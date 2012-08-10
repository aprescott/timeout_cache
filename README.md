# TimeoutCache

A `TimeoutCache` is a simple cache where objects are stored with a fixed expiration time. It is useful when you want to keep an object around for a sufficiently long period of time, but want them to disappear after, say, 5 seconds, or on the first day of next month.

```
gem install timeout_cache
```

# How do I use this thing?

A `TimeoutCache` is easy to use.

```ruby
cache = TimeoutCache.new
cache[:foo] = :bar
cache[:foo] #=> bar

# wait some time (by default, 60 seconds)

cache[:foo] #=> nil
```

By default, retrievals return `nil` 60 seconds after they're put into the cache. You can control the length of time by using `#set` with the `:time` option:

```ruby
cache.set(:a, :b, :time => 5)
cache[:a] #=> :b
sleep 5
cache[:a] #=> nil
```

You can also use an instance of `Time`:

```ruby
cache.set(:x, :y, :time => Time.now + 50)
```

You can use any object as the value for `:time` provided it is an `Integer`, a `Time`, has a `to_int` method, or has a `to_time` method.

If you want to change the default expiration time, do so when you make a new instance of `TimeoutCache` by passing the length of time in seconds.

```ruby
cache = TimeoutCache.new(10 * 60 * 60) # 10 hours
```

Unless an object is added to the cache using the `:time` option, the default is used. This default length of time is 60 seconds.

# Entry deletion and pruning

Expired entries are deleted lazily to try and avoid to cost of excessively pruning. If an entry is added with an expire time of 15 seconds and nothing touches the cache, the entry will still be in the cache after 20 seconds. Expired entries are deleted when certain methods are called:

* `#[]` (or, equivalently, `#get`) provided that the entry being retrieved has expired
* `#size`
* `#empty?`

If you want to manually prune the cache, you may do so by calling `#prune`.

# Documentation

There's not much to the code, but it's all commented and you can generate documentation with `rake docs`.

# Tests

You can run the tests with `rake test`.

# License / Copyright

Copyright (c) 2012 Adam Prescott, released under the MIT license. See the LICENSE file for details.

# Contributing

The official repository is on GitHub at [aprescott/timeout_cache](https://github.com/aprescott/timeout_cache). Issues should be opened there, as well as pull requests. Submissions should be on a separate feature branch:

* Fork and clone
* Create a feature branch
* Add code and tests
* Run all the tests
* Push you branch to your GitHub repository
* Send a pull request

Your contribution will be assumed to also be licensed under the MIT license.
