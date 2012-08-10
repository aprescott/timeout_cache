# Copyright (c) 2012 Adam Prescott, licensed under the MIT license. See LICENSE.

#
# TimeoutCache is a simple key-value store where entries expire after a certain
# time. It implements parts of the Hash interface.
#
#     cache = TimeoutCache.new
#     cache[:foo] = :bar
#     cache[:foo] #=> bar
#
#     # wait some time (by default, 60 seconds)
#
#     cache[:foo] #=> nil
#
class TimeoutCache
  VERSION = "0.0.1"
  
  # Wraps an object by attaching a time to it.
  class TimedObject # :nodoc:
    attr_reader :value, :expires_at
    
    def initialize(value, time)
      @value = value
      @expires_at = time
    end
    
    # Returns true if the object has expired.
    # Returns false if the object has not yet expired.
    def expired?
      @expires_at <= Time.now
    end
  end
  
  # The default number of seconds an object stays alive.
  DEFAULT_TIMEOUT = 60
  
  attr_reader :timeout
  
  # Creates a new TimeoutCache.
  #
  # If <tt>timeout</tt> is specified, the default survival time for
  # a cache entry is <tt>timeout</tt> in seconds.
  #
  # If no default value is used, then DEFAULT_TIMEOUT is the default
  # time-to-expire in seconds.
  def initialize(timeout = DEFAULT_TIMEOUT)
    raise ArgumentError.new("Timeout must be > 0") unless timeout > 0
    
    @timeout = timeout
    
    # we can use this for look-ups in O(1), instead of only find-min in O(1)
    @store = {}
  end
  
  # Returns the number of items in the cache.
  def size
    @store.size
  end
  alias_method :length, :size
  
  # Returns the value for the given key. If there is no such key in the cache,
  # then this returns nil. If the value has an expire time earlier than or equal
  # to the current time, this returns nil.
  #
  # As an implementation detail, this method calls #prune whenever it finds
  # an element that has expired.
  def [](key)
    val = @store[key]
    
    if val
      if val.expired?
        prune
        nil
      else
        val.value
      end
    else
      nil
    end
  end
  alias_method :get, :[]
  
  # Returns the expire time of the value for the given key.
  def expire_time(key)
    @store[key].expires_at
  end
  
  # Stores an object in the cache with an expire time DEFAULT_TIMEOUT
  # seconds from now.
  def []=(key, value)
    v = TimedObject.new(value, Time.now + timeout)
    @store[key] = v
  end
  
  # Stores an object in the cache. options is a hash with symbol keys:
  #
  # :time:: can be either an Integer representing the number of seconds the object should be alive
  #         or a Time object representing a fixed time.
  #
  # If time is not specified in the hash, the default timeout length is used.
  #
  # If the object would expire immediately, returns nil, otherwise returns the object stored.
  def set(key, value, options = {})
    time = options[:time] || timeout
    
    time = case time
           when Integer
             Time.now + time
           when Time
             time
           end
    
    return nil if time <= Time.now
    
    v = TimedObject.new(value, time)
    @store[key] = v
    
    value
  end
  
  # Returns true if the cache is empty, otherwise false.
  def empty?
    @store.empty?
  end
  
  # Deletes the key-value pair for the given key.
  #
  # Returns nil if there is no such key, otherwise returns the deleted value.
  def delete(key)
    v = @store.delete(key)
    v ? v.value : v
  end
  
  # Removes any expired entries from the cache.
  #
  # If nothing was removed, returns nil, otherwise returns
  # the number of elements removed.
  def prune
    return nil if empty?
    
    count = 0
    
    @store.delete_if { |k, v| v.expired? && count += 1 }
    
    count == 0 ? nil : count
  end
  
  def inspect
    %Q{#<#{self.class} #{@store.inspect}>}
  end
end
