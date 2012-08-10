require "timeout_cache"
require "rspec"
require "timecop"

describe TimeoutCache do
  def sleep(n)
    Timecop.travel(Time.now + n)
  end
  
  after :all do
    # If we don't return, the runtime for the tests makes it seem like
    # we had actually slept!
    Timecop.return
  end

  it "uses the global default timeout with no time specified" do
    subject.timeout.should == TimeoutCache::DEFAULT_TIMEOUT
  end
  
  it "uses a specified timeout if one is given" do
    TimeoutCache.new(50).timeout.should == 50
  end
  
  it "can be instantiated with anything that responds to to_int" do
    x = double("")
    x.should_receive(:to_int).and_return(2)
    
    c = TimeoutCache.new(x)
    c[:a] = :b
    c[:a].should == :b
    sleep 3
    c[:a].should be_nil
  end
  
  it "cannot be instantiated with a global timeout <= 0" do
    [0, -1, -5].each do |i|
      expect { TimeoutCache.new(i) }.to raise_error(ArgumentError)
    end
    
    expect { TimeoutCache.new(1) }.to_not raise_error
  end
  
  describe "#set" do
    it "sets the given key-value pair" do
      subject.set(:a, 1)
      subject.get(:a).should == 1
    end
    
    it "sets the given key-value pair with a timeout" do
      t = Time.now + 10
      subject.set(:a, 1, :time => t)
      subject.expire_time(:a).should == t
    end
    
    context "if the :time value is neither a Time nor an Integer" do
      it "accepts any object which responds to #to_time" do
        s = double("")
        s.should_receive(:to_time).and_return(Time.now + 2)
        
        subject.set(:a, 5, :time => s)
        subject[:a].should_not be_nil
        sleep 3
        subject[:a].should be_nil
      end
      
      it "accepts any object which responds to #to_int" do
        s = double("")
        s.should_receive(:to_int).any_number_of_times.and_return(2)
        
        subject.set(:a, 5, :time => s)
        subject[:a].should_not be_nil
        sleep(s.to_int + 1)
        subject[:a].should be_nil
      end
      
      it "throws ArgumentError if it can't get a time out of it" do
        expect { subject.set(:a, :b, :time => "not a time") }.to raise_error(ArgumentError)
      end
    end
    
    # here be dragons. if it takes too long to execute these
    # commands, the times won't match, so this test isn't deterministic
    it "sets a default timeout time with no time value specified" do
      t = Time.now + subject.timeout
      subject.set(:a, 1)
      subject.expire_time(:a).should_not be_nil
      subject.expire_time(:a).to_i.should == t.to_i
    end
    
    it "doesn't set a value if the timeout time is <= now" do
      subject.set(:a, 1, :time => Time.now)
      subject.get(:a).should be_nil
    end
    
    it "can have a negative time value" do
      expect { subject.set(:a, 1, :time => -1) }.to_not raise_error
      subject.get(:a).should be_nil
    end
  end
  
  describe "#get" do
    it "returns nil if there is no matching key" do
      subject.get(:no_such_key).should be_nil
    end
    
    it "returns nil if the object has expired" do
      subject.set(:a, 1, :time => 1)
      subject.get(:a).should == 1
      sleep 2
      subject.get(:a).should be_nil
    end
  end
  
  describe "#prune" do
    it "erases expired entries" do
      subject.set(:a, 1, :time => 1)
      subject.get(:a).should == 1
      sleep 2
      subject.prune
      subject.get(:a).should be_nil
    end
    
    it "returns nil if nothing was pruned" do
      subject.prune.should be_nil
    end
  end
  
  describe "#delete" do
    it "deletes entries from the cache" do
      subject[0] = 1
      subject.delete(0)
      subject[0].should be_nil
    end
    
    it "returns nil if nothing was deleted" do
      subject[:no_such_key].should be_nil
      
      subject[0] = 1
      subject.delete(0)
      subject.delete(0).should be_nil
    end
    
    it "returns the value deleted if the key is deleted" do
      subject[0] = 1
      subject.delete(0).should == 1
    end
  end
  
  describe "#size" do
    it "returns the number of entries in the cache" do
        subject.size.should == 0
        subject[:a] = :b
        subject.size.should == 1
        (1..10).each { |n| subject[n] = n }
        subject.size.should == 11
    end
    
    it "is 0 if the cache is empty" do
        subject.empty?.should be_true
        subject.size.should == 0
    end
    
    it "is non-zero if the cache is empty" do
        subject[:a] = 1
        subject.size.should_not == 0
    end
    
    it "ignores expired entries" do
      subject.set(:a, :b, :time => 1)
      sleep 2
      subject.size.should == 0
    end
  end
  
  describe "pruning" do
    it "happens when calling #get(key) when get(key) is expired" do
      subject.set(:a, 1, :time => 2)
      subject.set(:b, 1, :time => 2)
      sleep 3
      subject.should_receive(:prune)
      subject.get(:a)
    end

    it "does not happen when calling #get(key) when get(key) is not expired" do
      subject.set(:a, 1, :time => 200)
      subject.set(:b, 1, :time => 2)
      sleep 3
      subject.should_not_receive(:prune)
      subject.get(:a)
    end
    
    it "happens on #size call" do
      subject.should_receive(:prune)
      subject.size
    end
    
    it "happens on an #empty? call" do
      subject.should_receive(:prune)
      subject.empty?
    end
  end
  
  describe "#empty?" do
    it "is true if the cache is empty" do
      subject.empty?.should be_true
    end
    
    it "is false if the cache is not empty" do
      subject.set(:a, 1)
      subject.empty?.should be_false
    end
  end
end

describe TimeoutCache::TimedObject do
  describe "#expired?" do
    it "returns true for expire time > now" do
      TimeoutCache::TimedObject.new(:value, Time.now + 50)
    end
    
    it "returns false for expire time < now" do
      TimeoutCache::TimedObject.new(:value, Time.now - 50)
    end
    
    it "returns false for expire time = now" do
      TimeoutCache::TimedObject.new(:value, Time.now)
    end
  end
end
