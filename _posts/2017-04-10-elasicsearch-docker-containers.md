---
title: Running Elasticsearch Docker Containers with Rails
tags: docker elasticsearch
---

When starting to work with the [elasticsearch-rails][elasticsearch-rails] gem
the first thing I wanted to do is install the bundles and run the tests to ensure
I had a workable local environment. As per the README, run:

```
git clone https://github.com/elastic/elasticsearch-rails.git
cd elasticsearch-rails/
bundle install
rake bundle:install
rake test:all
```

I quickly hit some errors due to the fact I did not have an Elasticsearch
cluster running on port 9250. Since I started using Docker I am hesitant to
install services locally which I only really need for development purposes. The
following are notes from some snags I hit while using Docker to run a
development Elasticsearch service.

## Elasticsearch Docker Containers FTW!

The [Elasticsearch Docker][elasticsearch-docker] states that you can run a quick
and dirty elasticsearch server for development via:

```
docker run -p 9200:9200 \
  -e "http.host=0.0.0.0" \
  -e "transport.host=127.0.0.1" \
  docker.elastic.co/elasticsearch/elasticsearch:5.3.0
```

This does indeed work, but the docker image comes with X-Pack preinstalled and
requires a username:password on each request to the cluster. Authentication
should not be bypassed on any externally deployed clusters, but this was a bit
annoying for local development.

```
➜  elasticsearch-rails git:(master) curl "localhost:9200?pretty"
{
  "error" : {
    "root_cause" : [
      {
        "type" : "security_exception",
        "reason" : "missing authentication token for REST request [/?pretty]",
        "header" : {
          "WWW-Authenticate" : "Basic realm=\"security\" charset=\"UTF-8\""
        }
      }
    ],
    "type" : "security_exception",
    "reason" : "missing authentication token for REST request [/?pretty]",
    "header" : {
      "WWW-Authenticate" : "Basic realm=\"security\" charset=\"UTF-8\""
    }
  },
  "status" : 401
}
➜  elasticsearch-rails git:(master) curl -u elastic:changeme "localhost:9200?pretty"
{
  "name" : "gY73OoH",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "dU-m59spSeK9xPvwxiEXdg",
  "version" : {
    "number" : "5.3.0",
    "build_hash" : "3adb13b",
    "build_date" : "2017-03-23T03:31:50.652Z",
    "build_snapshot" : false,
    "lucene_version" : "6.4.1"
  },
  "tagline" : "You Know, for Search"
}
```

The authentication can be disabled by passing `xpack.security.enabled=false` as
an option, so the full command is:

```
docker run -p 9200:9200 \
  -e "http.host=0.0.0.0" \
  -e "transport.host=127.0.0.1" \
  -e "xpack.security.enabled=false" \
  docker.elastic.co/elasticsearch/elasticsearch:5.3.0
```

I don't want to have to remember all those options to bring the container up
again later. As long as you don't use the `--rm` option, the container will
persist and can be started again later. To make that easier we can pass a couple
more options to give the container a name and a more descriptive cluster name to
Elasticsearch.

```
docker run -p 9200:9200 \
  -e "http.host=0.0.0.0" \
  -e "transport.host=127.0.0.1" \
  -e "xpack.security.enabled=false" \
  -e "cluster.name=es-rails" \
  --name es-rails-elasticsearch
  docker.elastic.co/elasticsearch/elasticsearch:5.3.0
```

The Elasticsearch service can then be listed via `docker ps -a` and easily
restarted later via:

```
docker start -a es-rails-elasticsearch
```

Running the elasticsearch-rails tests require an Elasticsearch cluster running
on port 9250. A second elasticsearch cluster can be created to work with tests.

```
docker run -p 9250:9200 \
  -e "http.host=0.0.0.0" \
  -e "transport.host=127.0.0.1" \
  -e "xpack.security.enabled=false" \
  -e "cluster.name=es-rails-test" \
  --name es-rails-elasticsearch-test
  docker.elastic.co/elasticsearch/elasticsearch:5.3.0
```

We could then have 2 independent Elasticsearch clusters running, one on port
9200 for developement, and one on port 9250 for the test suite.


Running the elasticsearch-rails tests via `bundle exec rake test:all` will now
pass.

## Docker Compose

For a longer running development project that also requires a Rails server, you
could add a more robust Elasticsearch service to your docker-compose.yml, similar
to the one described by the
[elasticsearch docker docs][elasticsearch-docker-compose].

```
version: '2'
services:
  web:
    build: .
    command: bundle exec rails server --port 3000 --binding '0.0.0.0'
    ports:
      - "3000:3000"
    volumes:
      - .:/app
    links:
      - elasticsearch
    environment:
      - ELASTICSEARCH_URL=http://elasticsearch:9200
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:5.3.0
    ports:
      - "9200:9200"
    environment:
      - bootstrap.memory_lock=true
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
      - "http.host=0.0.0.0"
      - "transport.host=127.0.0.1"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    mem_limit: 1g
    cap_add:
      - IPC_LOCK
    volumes:
      - /usr/share/elasticsearch/data
```

With a Dockerfile for the web process looking something like

```
FROM ruby:2.4
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install
ADD . /app
```

Note how the `web` process connects to Elasticsearch via
`http://elasticsearch:9200` instead of localhost because they are not running in
the same container. Docker exposes this network link due to the `links` property
defined for the `web` service.


[elasticsearch-rails]: https://github.com/elastic/elasticsearch-rails
[elasticsearch-docker]: https://www.elastic.co/guide/en/elasticsearch/reference/5.0/docker.html
[elasticsearch-docker-compose]: https://www.elastic.co/guide/en/elasticsearch/reference/5.3/docker.html#docker-prod-cluster-composefile
