---
title: Ruby BCrypt Primer
layout: post
date: 2017-03-28
tags: dev
---

These are just some quick notes after playing with the Ruby BCrypt gem. I had
read [this article][crackstation] and realized I wasn't really sure how the
implementation of password storage worked in some past projects since I have not
had to store password salt separately.

## BCrypt Password Basics

The following shows how BCrypt can neatly store all the information needed in a
single field.

```ruby
require 'bcrypt'

password = BCrypt::Password.create("lame_password")

## password.to_s contains salt + hashed password
password.to_s # => "$2a$10$NX8y4tG4RkfRFdbfAKUmIO/S3yY1Nn4Vgr6omFaUKhuBdeoX0GK5W"
password.salt # => "$2a$10$NX8y4tG4RkfRFdbfAKUmIO"
password.checksum                          # => "/S3yY1Nn4Vgr6omFaUKhuBdeoX0GK5W"

## Salt contains $version$cost$salt
password.salt   # => "$2a$10$NX8y4tG4RkfRFdbfAKUmIO"
password.version # => "2a"
password.cost        # => 10
```

The salt generated is different for each password created, even if the secret is
the same.

```ruby
p2 = BCrypt::Password.create("lame_password")
p2.salt == password.salt # => false
```

Because `BCrypt::Password` stores the salt together with the secured secret, it
can be stored in a single field of a database and recalled to use the same salt
when comparing a newly provided secret.

The `bcrypt` gem uses an [`==` override][bcrypt-equal] to make this really simple:

```ruby
class BCrypt::Password
  # <snip>
  def ==(secret)
    super(BCrypt::Engine.hash_secret(secret, @salt)
  end
  alias_method :is_password?, :==
  # <snip>
end

password == "not_password"  # => false
password == "lame_password" # => true
```

This way the salt from the originally stored secret can be used for future
comparisons.


## Ruby on Rails Usage

[`ActiveModel::SecurePassword`][active-model-secure-password] uses essentially
this same code when you add a password to a model using the
`has_secure_password` mechanism.

From the [rails docs][active-model-docs]:

```ruby
class User < ActiveRecord::Base
  has_secure_password validations: false
end

user = User.new(name: 'david', password: 'mUc3m00RsqyRe')
user.save
user.authenticate('notright')      # => false
user.authenticate('mUc3m00RsqyRe') # => user
```

The `#authenticate` method is basically what we showed above:
```ruby
def authenticate(unencrypted_password)
  BCrypt::Password.new(password_digest).is_password?(unencrypted_password) && self
end
```

where `password_digest` is the stored password on the `User` model.

Similarly, `user.password = 'new_password'` makes a familiar call to create a
secure encrypted password with the new secret:

```ruby
def password=(unencrypted_password)
  @password = unencrypted_password
  cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
  self.password_digest = BCrypt::Password.create(unencrypted_password, cost: cost)
end
```

[bcrypt-equal]: https://github.com/codahale/bcrypt-ruby/blob/23b0517e20e7ddf2e733c1bcdb22b0b12166f042/lib/bcrypt/password.rb#L65-L68
[crackstation]: https://crackstation.net/hashing-security.htm
[active-model-secure-password]: https://github.com/rails/rails/blob/903493871468d5d7bbca9eb9d3efae187afdb8b0/activemodel/lib/active_model/secure_password.rb
[active-model-docs]: http://api.rubyonrails.org/classes/ActiveModel/SecurePassword/InstanceMethodsOnActivation.html
