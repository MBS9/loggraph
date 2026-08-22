#define QUEUE_SIZE 64
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <curl/curl.h>
#include <json-c/json.h>

void queue_consumer();

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

    char *fifo_file = argv[1];

    pthread_t consumer_thread;

    pthread_create(&consumer_thread, NULL, (void *(*)(void *))queue_consumer, NULL);

start_again:
    // Read from the FIFO file and add items to the queue
    FILE *fifo = fopen(fifo_file, "r");
    if (!fifo)
    {
        perror("fopen");
        return 1;
    }
    while (1)
    {
        if (!fgets(buffer, sizeof(buffer), fifo))
        {
            // End of file or error
            fclose(fifo);
            goto start_again;
        }
        ssize_t bytes_read = strlen(buffer);
        if (head == (tail + QUEUE_SIZE - 1) % QUEUE_SIZE)
        {
            // Queue is full, wait for space
            continue;
        }
        if (bytes_read + 1 == sizeof(buffer))
        {
            // Input line is too long, discard it
            continue;
        }
        // Add item to the queue
        queue_item *item = &queue[head];
        *item = strdup(buffer);
        head = (head + 1) % QUEUE_SIZE;
    }

    pthread_join(consumer_thread, NULL);
}

void queue_consumer()
{
    CURL *curl;
    CURLcode res;
    struct curl_slist *headers = NULL;

    char *token = getenv("UPLOAD_TOKEN");
    char *endpoint = getenv("UPLOAD_ENDPOINT");
    if (!token || !endpoint)
    {
        fprintf(stderr, "UPLOAD_TOKEN and UPLOAD_ENDPOINT environment variables must be set\n");
        return;
    }
    char *authHeader = malloc(strlen("Authorization: Bearer ") + strlen(token) + 1);
    sprintf(authHeader, "Authorization: Bearer %s", token);
    free(token);

    if (curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK)
    {
        fprintf(stderr, "curl_global_init() failed\n");
        return;
    }

    while (1)
    {
        if (head == tail)
        {
            // Queue is empty, wait for new items
            continue;
        }

        queue_item *item = &queue[tail];

        curl = curl_easy_init();
        if (curl)
        {
            headers = curl_slist_append(NULL, "Content-Type: application/json");
            headers = curl_slist_append(headers, authHeader);
            curl_easy_setopt(curl, CURLOPT_URL, endpoint);
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, *item);
            res = curl_easy_perform(curl);
            if (res != CURLE_OK)
            {
                fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            }
            curl_slist_free_all(headers);
            curl_easy_cleanup(curl);
        }
        tail = (tail + 1) % QUEUE_SIZE;
        free(*item);
    }
    free(authHeader);
}
