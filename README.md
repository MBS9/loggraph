# Loggraph

## Overview

The goal of this project is to cluster bot traffic using a partially supervised approach in order to gain insights into common patterns of automated activity on the Internet.

## Motivation

Home labs and small self-hosted servers rarely experience highly specialized, targeted attacks. Instead, the primary security concern for most operators is large volumes of automated bot traffic.

To better understand the security risks facing home labs, it is important to analyze the types of bot activity that are most commonly observed, the vulnerabilities being targeted, and the broader trends affecting the threat landscape.

## Project Overview

As a first step, a web server was deployed to record incoming HTTP requests and store them in a SQL database. Each request is decomposed into a set of request parts, including the HTTP method, source IP address, host, endpoint, important headers, and other relevant attributes. These components are stored as separate atomic units.

A fully connected, undirected graph is then constructed, where each node represents a distinct HTTP request and the weight of each edge corresponds to the Jaccard similarity index between the sets of parts associated with the two requests. To reduce graph size and remove noise, edges with a weight below 0.3 are discarded. The resulting graph contains approximately 60,000 nodes, representing 60,000 distinct HTTP requests.

Next, the Leiden community detection algorithm is applied to cluster nodes within the graph. After discarding clusters with high heterogeneity scores and clusters containing only a single item, the algorithm produced 499 clusters. The DeepSeek API was then used to generate a label and a brief description for each cluster based on the requests it contained.

The distribution of request counts per cluster follows a long-tail distribution. The most common cluster size was 2 requests, while the mean cluster size was 116 requests. This indicates a strong positive skew. The standard deviation was 545 requests, demonstrating substantial variation in cluster size. The largest cluster contained 5,084 requests, and only 49 of the 499 clusters contained more than 100 requests. Consequently, most clusters were relatively small.

## Findings

The objective of this project was to identify commonly targeted applications and broader trends within bot traffic. Larger clusters are particularly interesting because they indicate that many distinct HTTP requests share common characteristics. These shared characteristics reveal recurring patterns in automated scanning and exploitation activity.

Among the 49 clusters containing more than 100 requests, several recurring themes emerged. After manually reviewing and categorizing these clusters, the following trends were identified:

1. WordPress is heavily targeted.
2. Vulnerabilities in PHP frameworks and PHP-based applications are frequently targeted.
3. Search engine crawlers are commonly observed.
4. Many malicious requests attempt to retrieve sensitive files such as `/.env`, `/.git/config`, and other well-known secret files, hoping that they have been inadvertently exposed.
5. Directory brute-forcing is a common activity.
6. Authentication endpoints are frequently probed for vulnerabilities and misconfigurations.
7. User-Agent spoofing is commonly observed in bot traffic.
8. A wide variety of exploit scanners are regularly encountered.
