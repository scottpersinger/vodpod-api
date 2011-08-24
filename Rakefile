require "#{File.dirname(__FILE__)}/lib/vodpod-api"
API.load

require "tasks/vodpod"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = API::VERSION 
    gem.name = "vodpod-api"
    gem.summary = "The Vodpod API library and application"
    gem.description = ""
    gem.email = "api@vodpod.com"
    gem.homepage = "http://vodpod.com"
    gem.authors = ["Vodpod"]

    gem.executables = ['vodpod-api']
    gem.default_executable = [nil]

    gem.files.exclude 'db'
    gem.files.exclude 'bin'
    gem.files.exclude 'plan'
    gem.files.exclude 'Rakefile'
    gem.files.exclude '.gitignore'

    gem.add_dependency 'sequel', '~> 3.3.0'
    gem.add_dependency 'ramaze', '~> 2009.07'
    gem.add_dependency 'json', '~> 1.1.7'
    gem.add_dependency 'libxml-ruby', '~> 1.1.3'
    gem.add_dependency 'riddle', '~> 0.9.8'
    gem.add_dependency 'crypt', '~> 1.1.4'
    gem.add_dependency 'vodpod-common', '~> 0.0.1'
    gem.add_dependency 'construct', '~> 0.1.3'
    gem.add_dependency 'trollop', '~> 1.14'

    gem.add_development_dependency 'bacon'
    gem.add_development_dependency 'rack-test'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end


