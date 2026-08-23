#define QUEUE_SIZE 64
#define _XOPEN_SOURCE 700
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <curl/curl.h>
#include <signal.h>
#include <errno.h>
#include "json.c"

void *queue_consumer(void *arg);

pthread_cond_t queue_not_empty = PTHREAD_COND_INITIALIZER;
pthread_mutex_t queue_mutex = PTHREAD_MUTEX_INITIALIZER;
volatile sig_atomic_t running = 1;

void handle_sigint(int sig)
{
    (void)sig;
    running = 0;
}

typedef char *queue_item;

// Head points to the item last added to the queue
unsigned int head = 0;
// Tail points to the item next to be removed from the queue
unsigned int tail = 0;

// If head == tail, the queue is empty
// If tail-1 == head, the queue is full

queue_item queue[QUEUE_SIZE];

char buffer[1024];

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("Usage: %s <fifo_file>\n", argv[0]);
        return 1;
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = handle_sigint;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    if (sigaction(SIGINT, &sa, NULL) != 0)
    {
        perror("sigaction");
        return 1;
    }

    char *fifo_file = argv[1];

    pthread_t consumer_thread;

    pthread_create(&consumer_thread, NULL, queue_consumer, NULL);

start_again:
    // Read from the FIFO file and add items to the queue
    FILE *fifo = fopen(fifo_file, "r");
    if (!fifo)
    {
        perror("fopen");
        return 1;
    }
    while (running)
    {
        if (!fgets(buffer, sizeof(buffer), fifo))
        {
            // EOF, read error, or interruption.
            if (!running)
            {
                break;
            }
            if (ferror(fifo) && errno == EINTR)
            {
                clearerr(fifo);
                continue;
            }
            fclose(fifo);
            goto start_again;
        }
        ssize_t bytes_read = strlen(buffer);
        if (bytes_read + 1 == sizeof(buffer))
        {
            // Input line is too long, discard it
            continue;
        }
        char *copy = strdup(buffer);

        copy[strcspn(copy, "\n")] = 0;

        pthread_mutex_lock(&queue_mutex);
        if (head == (tail + QUEUE_SIZE - 1) % QUEUE_SIZE)
        {
            // Queue is full; drop this item and keep reading.
            pthread_mutex_unlock(&queue_mutex);
            free(copy);
            continue;
        }
        // Add item to the queue
        queue_item *item = &queue[head];
        *item = copy;
        head = (head + 1) % QUEUE_SIZE;
        pthread_cond_signal(&queue_not_empty);
        pthread_mutex_unlock(&queue_mutex);
    }

    fclose(fifo);
    pthread_mutex_lock(&queue_mutex);
    pthread_cond_broadcast(&queue_not_empty);
    pthread_mutex_unlock(&queue_mutex);

    pthread_join(consumer_thread, NULL);
    return 0;
}

void *queue_consumer(void *arg)
{
    (void)arg;
    CURL *curl;
    CURLcode res;
    struct curl_slist *headers = NULL;

    char *token = getenv("UPLOAD_TOKEN");
    char *endpoint = getenv("UPLOAD_ENDPOINT");
    if (!token || !endpoint)
    {
        fprintf(stderr, "UPLOAD_TOKEN and UPLOAD_ENDPOINT environment variables must be set\n");
        return NULL;
    }
    char *authHeader = malloc(strlen("Authorization: Bearer ") + strlen(token) + 1);
    sprintf(authHeader, "Authorization: Bearer %s", token);

    if (curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK)
    {
        fprintf(stderr, "curl_global_init() failed\n");
        return NULL;
    }

    while (1)
    {
        pthread_mutex_lock(&queue_mutex);
        while (head == tail && running)
        {
            pthread_cond_wait(&queue_not_empty, &queue_mutex);
        }
        // Upload all items in the queue before exiting
        if (!running && head == tail)
        {
            pthread_mutex_unlock(&queue_mutex);
            break;
        }

        char *item = queue[tail];
        tail = (tail + 1) % QUEUE_SIZE;
        pthread_mutex_unlock(&queue_mutex);

        char *output_str = NULL;
        if (process_json(item, &output_str))
        {
            fprintf(stderr, "Failed to process JSON: %s\n", item);
            goto complete;
        }

        curl = curl_easy_init();
        if (!curl)
        {
            free(output_str);
            fprintf(stderr, "curl_easy_init() failed\n");
            goto complete;
        }

        headers = curl_slist_append(NULL, "Content-Type: application/json");
        headers = curl_slist_append(headers, authHeader);
        curl_easy_setopt(curl, CURLOPT_URL, endpoint);
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, output_str);
        res = curl_easy_perform(curl);
        if (res != CURLE_OK)
        {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
        }
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);

        free(output_str);
    complete:
        free(item);
    }
    curl_global_cleanup();
    free(authHeader);
    return NULL;
}
