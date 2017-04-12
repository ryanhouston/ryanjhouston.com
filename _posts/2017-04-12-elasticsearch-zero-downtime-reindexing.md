---
title: Elasticsearch Zero-Downtime Reindexing
tags: elasticsearch
---

When working with Elasticsearch, at some point you'll need to update your
mapping. You may be able to use the [PUT mapping][es-put-mapping] to add new
fields to an existing index, then reindex your documents with the new field data
without having to recreate the whole index. Sometimes you need to change an
analyzer or make deeper changes that require creating a new index. This can mean
downtime while the existing index is deleted, the new index is created with the
new mapping, and all your documents are indexed from the source of truth,
perhaps a relational database, in order to fill in the new fields.

## Once upon a time...

In a past project our reindexing process would take about an hour to index
600,000+ documents while some critical features of the product were dependent
upon our Elasticsearch index. An hour of downtime for reindexing was not an
option. At the time, the [elasticsearch-rails][es-rails] gem was in progress but
not yet released. Our team was also weary of solutions that used mixins to add
major functionality to ActiveRecord models, which in many applications already
do too much. I wrote a simple gem, [elasticsearch-documents][es-docs], which is
mostly just a layer of helpers and convention on top of
[elasticsearch-ruby][es-ruby] and adds minimal code as a mixin for ActiveRecord
models in order to transform them into a hash that could be indexed into
Elasticsearch. Simple query objects could also be created as essentially POROs,
but it was up to the client application to map the Elasticsearch document
results back to ActiveRecord models and sort those according to the search
score. The point of this gem was to have no knowledge of Rails. There are plenty
of things I no longer like about the design of this gem, and I would not
recommend it's use over the now mature elasticsearch-ruby and
elasticsearch-rails gems.

## Zero-downtime Reindexing with Aliases (an experiment)

The experiment with elasticsearch-documents did provide an opportunity to design
a [solution for zero-downtime reindexing][aliased-indexer] using indexes that
were named with a timestamp appended and [index aliases][es-aliases] to point to
the active index. The solution I chose was to have a read alias and a write
alias. The reindexing process looks like:

1. Both read and write aliases point to the current active index which was named
   something like `app_20170402125326`
2. The reindex is started which creates a new index with the current timestamp
   appended, `app_20170411100542`
3. The write alias, named like `app_write`, is changed to point to the newly
   created index
4. The documents are indexed to the write alias
5. The read alias, named like `app_read`, is changed to point to the newly
   created index
6. The old index is deleted.

Reads and writes are now using the new index that was hot-swapped in without the
application seeing any downtime. One implication of this strategy is that newly
created, updated, or deleted document writes only hit the new index during the
reindexing process. This means your application searches could see stale data
during this time and new data will not show up until the reindex is complete.
With our particular application use-cases this was an acceptable trade off and
largely not noticeable to the users. It is not hard to imagine a solution that
would write to both the new and old indexes when the read and write aliases did
not point to the same index.

## Other resources

There are good resources out there on zero-downtime elasticsearch reindexing
with some giving examples of accomplishing this with `elasticsearch-rails`.

- <https://www.elastic.co/blog/changing-mapping-with-zero-downtime>
- <https://www.elastic.co/guide/en/elasticsearch/guide/current/index-aliases.html>
- <https://berislavbabic.com/refresh-your-elasticsearch-index-with-zero-downtime/>
- <https://summera.github.io/infrastructure/2016/07/04/reindexing-elasticsearch.html>


[es-aliases]: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html
[es-docs]: https://github.com/ryanhouston/elasticsearch-documents
[es-put-mapping]: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-put-mapping.html
[es-rails]: https://github.com/elastic/elasticsearch-rails
[es-ruby]: https://github.com/elastic/elasticsearch-ruby
[aliased-indexer]: https://github.com/ryanhouston/elasticsearch-documents/blob/db7d175265111eae7afe27b4d522cfe630f80602/lib/elasticsearch/extensions/documents/aliased_index_store.rb
