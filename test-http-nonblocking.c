/* Regression test: a stalled HTTP endpoint must not block other devices
 * or the event-loop timeout. See LICENSE for license terms.
 */
#include "airscan.h"

#include <arpa/inet.h>
#include <assert.h>
#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

static int listener, stop_pipe[2], completed;
static bool healthy_ok, stalled_ok;
static pthread_cond_t completed_cond = PTHREAD_COND_INITIALIZER;

static void *
serve (void *unused)
{
    char buf[4096];
    int slow, healthy;
    const char partial[] = "HTTP/1.1 200 OK\r\nContent-Length: 20\r\n\r\nx";
    const char full[] = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok";

    (void) unused;
    slow = accept(listener, NULL, NULL);
    assert(slow >= 0);
    assert(recv(slow, buf, sizeof(buf), 0) > 0);
    assert(send(slow, partial, sizeof(partial) - 1, 0) == sizeof(partial) - 1);

    healthy = accept(listener, NULL, NULL);
    assert(healthy >= 0);
    assert(recv(healthy, buf, sizeof(buf), 0) > 0);
    assert(send(healthy, full, sizeof(full) - 1, 0) == sizeof(full) - 1);
    close(healthy);

    /* Keep the partial response open until the client's timeout fires. */
    assert(read(stop_pipe[0], buf, 1) == 1);
    close(slow);
    return NULL;
}

static void
on_response (void *unused, http_query *q)
{
    (void) unused;
    if (http_query_get_uintptr(q) == 0) {
        error err = http_query_error(q);
        stalled_ok = err != NULL && !strcmp(ESTRING(err), "timeout");
    } else {
        http_data *data = http_query_get_response_data(q);
        healthy_ok = http_query_error(q) == NULL &&
            http_query_status(q) == 200 && data != NULL &&
            data->size == 2 && !memcmp(data->bytes, "ok", 2);
    }
    completed ++;
    pthread_cond_signal(&completed_cond);
}

int
main (void)
{
    struct sockaddr_in addr;
    socklen_t addrlen = sizeof(addr);
    pthread_t server;
    http_client *client;
    log_ctx *log;
    char uri[128];
    int i;

    /* A blocking regression must fail, never hang the test suite. */
    alarm(5);
    assert(pipe(stop_pipe) == 0);
    listener = socket(AF_INET, SOCK_STREAM, 0);
    assert(listener >= 0);
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    assert(bind(listener, (struct sockaddr*) &addr, sizeof(addr)) == 0);
    assert(getsockname(listener, (struct sockaddr*) &addr, &addrlen) == 0);
    assert(listen(listener, 2) == 0);
    assert(pthread_create(&server, NULL, serve, NULL) == 0);

    log_init();
    assert(eloop_init() == SANE_STATUS_GOOD);
    assert(http_init() == SANE_STATUS_GOOD);
    eloop_mutex_lock();
    log = log_ctx_new("HTTP regression", NULL);
    client = http_client_new(log, NULL);
    for (i = 0; i < 2; i ++) {
        http_query *q;
        snprintf(uri, sizeof(uri), "http://127.0.0.1:%u/%s",
                 ntohs(addr.sin_port), i == 0 ? "stalled" : "healthy");
        q = http_query_new(client, http_uri_new(uri, true), "GET", NULL, NULL);
        http_query_set_uintptr(q, i);
        http_query_timeout(q, i == 0 ? 250 : 1000);
        http_query_submit(q, on_response);
    }
    eloop_mutex_unlock();
    eloop_thread_start();
    eloop_mutex_lock();
    while (completed < 2) {
        eloop_cond_wait(&completed_cond);
    }
    eloop_mutex_unlock();
    eloop_thread_stop();
    assert(write(stop_pipe[1], "x", 1) == 1);
    pthread_join(server, NULL);
    close(listener);
    close(stop_pipe[0]);
    close(stop_pipe[1]);
    http_client_free(client);
    log_ctx_free(log);
    http_cleanup();
    eloop_cleanup();
    log_cleanup();
    pthread_cond_destroy(&completed_cond);
    alarm(0);
    assert(healthy_ok && stalled_ok);
    puts("HTTP concurrency and timeout: PASS");
    return 0;
}
