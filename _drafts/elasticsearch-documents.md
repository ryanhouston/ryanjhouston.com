---
title: Using elasticsearch-ruby with Ruby on Rails
layout: post
category: nerdery
date: 2014-08-18
---

At [Culturalist](http://culturalist.com) we use Elasticsearch hosted by
[bonsai](http://bonsai.io) for our search needs. Culturalist is built on Ruby on
Rails using ActiveRecord as most Ruby on Rails applications do.  When we began
using Elasticsearch we used the [Tire Gem](https://github.com/karmi/tire) to map
our models to an Elasticsearch index and search the indexed data. While Tire is
still currently maintained, as of September 2013 [Tire has been
retired](https://github.com/karmi/retire/wiki/Tire-Retire) in favor of a new
Gem, [elasticsearch-ruby](https://github.com/elasticsearch/elasticsearch-ruby).

The new Elasticsearch gem does not yet provide any integrations with Rails, and
specifically with ActiveRecord, though it looks like Rails integrations are in
the works. Tire and other Gems that integrate with ActiveRecord models can tempt
developers to dump extra responsibilities into the applications core models.
This tends to result in all parts of the application being tightly coupled with
ActiveRecord. At [Culturalist](http://culturalist.com) we first attempted to
remedy this by keeping the tire interactions in separate modules that were
included into the ActiveRecord models. At the end of the day the object space of
the models still end up polluted with too many responsibilities.

## Time for a New Approach

After reading the post about Tire becoming Retire[d], we decided to see what it
would look like if we tried to migrate from Tire to
[elasticsearch-ruby](https://github.com/elasticsearch/elasticsearch-ruby). At
the time there was no real Rails integration to speak of in elasticsearch-ruby.
This left us the freedom to try a different approach that would keep our
Elasticsearch interactions more insulated from Activerecord and the rest of the
application.

Elasticsearch is a wonderful and powerful tool. I love it and am still learning
how to use it effectively. Attempting to harness the power of this great, yet
complex, tool on top of an ActiveRecord model can quickly become unwieldy in my
experience.  Your database tables may not map exactly to your search index
documents or require some sort of data transformation before indexing.  The
serialization of that data is a separate responsibility from the main
responsibility of Activerecord models which is persistence of your data to the
database (this can be debated that AR is pulling at least double-duty as value
objects and repository objects, but that is not the focus of this post. Lets
just agree to keep AR models free of unnecessary responsibilities).  Because
Elasticsearch indexes are more of a document store, your data may not need to be
normalized in the same ways that your application stores your data in a
traditional relational database. So instead of using mixins to include search
engine behaviors into ActiveRecord models, at Culturalist we chose to use a set
of wrapper classes to serialize our models to search index documents. I think
this approach probably draws some parallels with
[ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers)
by providing a class which has a single responsibility to serialize a type of
object into an Elasticsearch document that can be indexed.

The new elasticsearch-ruby Gem contains bindings to the core Elasticsearch API
endpoints. The elasticsearch-transport Gem is included in the main Gem and
contains a robust client for handling the HTTP requests to your cluster.  The
elasticsearch-api Gem contains bindings to all the actions you can perform on
your index and cluster. To index a document you essentially just pass a hash
representation of the JSON request you wish to send to your index.

{% highlight ruby %}
user_document = { name: 'Joe', bio:  'Lorem ipsum' }

payload  = {
  index_name: 'test_index',
  type:       'user',
  id:         1,
  body:       user_document,
}

Elasticsearch::Client.new.index(payload)
{% endhighlight %}

*TODO*: introduce elasticsearch-extensions-documentor in this example

In the Culturalist code we like to keep this explicitly separate from the model
class with a search document wrapper class.

{% highlight ruby %}
module SearchDocuments
  class User
    attr_reader :model

    def initialize(model)
      @model = model
    end

    def self.type
      'user'
    end

    def id
      model.id
    end

    def type
      self.class.type
    end

    def document_hash
      {
        name: model.name,
        bio:  model.bio,
      }
    end

  end
end

user_document = Search::Document::User.new(User.find(1))

payload = {
  index_name: 'test_index',
  type:       user_document.type,
  id:         user_document.id
  body:       user_document.document_hash,
}

Elasticsearch::Client.new.index(payload)

{% endhighlight %}

Using this strategy our Search::Document classes and unit tests can be
completely decoupled from ActiveRecord and just use POROs.

{% highlight ruby %}
class MockUser
  def id
    1
  end

  def name
    'Joe'
  end

  def bio
    'Lorem Ipsum'
  end
end

module Search
  module Documents
    describe User do
      let(:user) { MockUser.new }
      subject { User.new(user) }

      it 'provides a document hash' do
        doc_hash = { name: 'Joe', bio: 'Lorem Ipsum' }
        expect(subject.document_hash).to eq doc_hash
      end

    end

  end
end
{% endhighlight %}

Combine this with a spec helper that does not load up all of Rails or even
ActiveRecord, this spec will run in less than a second instead of 10+ seconds
when using the default `spec_helper` of a Rails application  that loads up all
of Rails even when we don't need it.

## Searching

So now that we have indexed our data into the search index, we probably want to
search the index. We can create a set of classes to encapsulate our specific
search use-cases. At [Culturalist]( http://culturalist.com) we have couple
different types of searches. The first one is a common full site search which
looks something like the following.

{% highlight ruby %}
module Search
  module Query
    class QueryStringSearch

      attr_reader :query_string

      def initialize(search_string)
        @query_string = search_string
      end

      def as_hash
        # TODO fill in implementation
      end

    end
  end
end

query = Search::Query::QueryStringSearch.new('search for this string')
results = Elasticsearch::Extensions::Documentor.new.search(query)

{% endhighlight %}

We are still totally decoupled from ActiveRecord. We can search the index
without ever touching our database or loading the ActiveRecord library. If we
want to load the models we can just pluck the IDs out of the result documents
and then use ActiveRecord to load up all the models for those IDs.

{% highlight ruby %}
ids = results.hits.hits.collect {|result| result._id }
users = User.where(id: ids)
{% endhighlight %}

## Conclusion

I realize this has resulted in writing more code than was probably
necessary when using Tire. I think this is a great trade-off for attempting to
keep the core ActiveRecord models of the application closer to SRP classes and
not having a single object worry about being a value object, persistence layer,
and search interface.  The resulting individual unit tests provide a much faster
feedback loop than if we had to load up ActiveRecord and all of Rails just to
test interactions that could have been performed with a PORO.

