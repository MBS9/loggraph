# LogGraph

This is a log analytics project.

Key technologies used:
- PostgreSQL
- PostgREST (for API server)
- Next.js (frontend app)

## Endpoints

The endpoints will collect logs. In this project, these endpoints will be NGINX instances, who write access log to a FIFO pipe. This FIFO pipe is consumed by an application, which initially writes access logs to an in memory, circular queue. If the queue is full, the request is dropped to avoid blocking NGINX.

From another thread, the application then uploads the logs to PostgREST from the circular queue.

## PostgreSQL

The PostgreSQL db will contain a view, with a write rule. New logs will be inserted into this view. A sample insert may look like this:

```json
{
    "method": "GET",
    "host": "host",
    "path": "/example/test",
    "host": "example.org",
    "query_string": "?hello=true&example=true",
    "headers": "Content-Type: application/json\nAccept: */*",
}
```

The write rule will normalize this into the following tables:
- request (request_id, part_count, timestamp)
- request_to_part (request_id, part_id)
- request_part(part_id, part (text), part_type_id)
- part_type(type_id, display_name)

part_type will only contain the following: method, host, query_part, endpoint_part.

Different requests may share the same request_part (for HTTP methods, they most certainly will). In this case, request_part will not be duplicated.

Endpoints and query strings will not be stored as single request_part, rather it will be split into multiple endpoint_parts/query_parts, which are stored sepperately. For exmaple: /hello/test, would be split into "hello" and "test", while "?query1=test&query2=test" would be split into "query1=test" and "query2=test".

The PostgreSQL db will contain a materialized view, that represents a graph of requests. There is an edge between requests if they have at least 1 non-excluded shared parts. The weight of the edge will be Jaccard index on the set of requests parts from the two requests. Excluded parts are ignored in this calculation.

The materialized view will be refreshed hourly by a cron job.

## Frontend

The frontend will use PostgREST to query the graph from the db, and will use a WASM implementation of Louvian clustering to find clusters of requests and display them to the user in a freindly UI.

## Authentication

PostgREST authentication will happen using JWT. Only authorized endpoints can write logs, but anyone can query the graph.
