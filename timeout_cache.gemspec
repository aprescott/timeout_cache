lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "timeout_cache"

Gem::Specification.new do |s|
  s.name         = "timeout_cache"
  s.version      = TimeoutCache::VERSION
  s.authors      = ["Adam Prescott"]
  s.email        = ["adam@aprescott.com"]
  s.homepage     = "https://github.com/aprescott/timeout_cache"
  s.summary      = "Simple time-based cache."
  s.description  = "Simple time-based cache."
  s.files        = Dir["{lib/**/*,test/**/*}"] + %w[timeout_cache.gemspec .gemtest LICENSE Gemfile rakefile README.md]
  s.require_path = "lib"
  s.test_files   = Dir["test/*"]
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
