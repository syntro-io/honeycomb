$:.push File.expand_path('../lib', __FILE__)

require 'honeycomb/version'

Gem::Specification.new do |s|
  s.name        = 'honeycomb'
  s.version     = Honeycomb::VERSION
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Test result report libraries'
  s.description = 'Formatters, parsers, and submitters for test results'
  s.authors     = ['Ashraf Ali']
  s.email       = ['ashrafali0148@gamil.com']
  s.files       = Dir['README.md', 'lib/**/*.rb', 'bin/honeycomb']
  s.executables = ['honeycomb']
  s.homepage    = 'https://github.com/syntro-io/honeycomb'
  s.license     = 'MIT'
  s.add_runtime_dependency 'json', '~> 1.8'
  s.add_runtime_dependency 'test_rail-api', '~> 0.4.1'
  s.add_runtime_dependency 'ox', '~> 2.2'
  s.add_runtime_dependency 'hive-messages', '~> 1'
  s.add_development_dependency 'rspec', '~>3.2'
end
