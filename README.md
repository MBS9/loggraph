# Loggraph

The goal of the project is to cluster bot traffic using a partially supervised algorithm, and to use this to gain insights into key bot activity.

# Motivations

Home labs, and small servers rarely see specialised, targetted attacks. Therefore, the main security concern for most labs is automated bot traffic.

It is therefore important to gain an in depth understanding of bot traffic, vulnerabilities targetted, to know the trends affecting security landscape of home labs.

# Project overview

As a first step, a webserver is setup that records all incomming HTTP requests, and stores them in a SQL database. Requests are broken down into request parts: method, source ip, host, endpoint, important headers, etc... are all stored as sepperate atomic units.

A fully connected undirected graph is compiled, with the nodes representing distinct requests, and the weight of the edges being the Jaccard similarity index of the set of parts in each requests. To decrease graph size and to remove noise, and edge whose weight is less then 0.3 is dropped. The final graph used contained roughly 60k nodes, i.e.: 60k distinct HTTP requests.

Next, the Leiden clustering algorithm is used to cluster nodes based on the graph. After dropping clusters whose heterogeniety score was very high, or contained only 1 item, the algorithm compiled 499 clusters. I used the Deepseek API to generate a label and a brief discription of the HTTP requests in each cluster.

The number of distinct requests in each cluster followed a long-tail distribution. The most commonly occuring request count in a cluster was 2, but with a mean request count of 116, the distribution had a strong postive skew. The std. deviation of this metric was 545, demonstrating that the spread is massive. The largest cluster contained 5084 requests, and of the 499 total, only 50 clusters contained more than 100 items. Therefore, most clusters were small.

The aim of this project was to identify the most commonly targetted applications, and the biggest trends in bot traffic. For this purpose, larger clusters are more interesting, since they demonstrate that many different HTTP requests share similar features. These shared features are the biggest trends in bot traffic, concluding the project. Of the 50 clusters that contained more than 100 requests, many clusters shared common themes. By manually compiling the themes, I determine that the trends are:

1. Wordpress is targetted a lot
2. Vulnerabilities PHP frameworks, applications are commonly targetted
3. Web crawlers for search engines are commonly seen
4. A lot of malicious requests try to download sensitive files such as /.env, /.git/config, or well known secret files for a range of services, hoping that they are insecurly exposed.
5. Directory brute force is commonly seen
6. Authentication endpoint probing, and searching for associated vulnerabilties
7. User agent spoofing, is commonly seen in bot traffic.
8. A range of differnet exploit scanners are commonly seen 
