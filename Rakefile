require 'lib/stylish'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = "stylish"
    s.summary = "Write CSS with Ruby"
    s.email = "benedict@eastaugh.net"
    s.homepage = "http://ionfish.github.com/stylish/"
    s.description = "A Ruby library for generating cascading stylesheets."
    s.authors = ["Benedict Eastaugh"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install " +
       "technicalpickles-jeweler -s http://gems.github.com"
end

task :default => :test

desc "Run the Stylish test suite"
task :test do
  require 'test/unit'
  
  puts "Stylish version #{Stylish::VERSION}"
  
  testdir = "test"
  Dir.foreach(testdir) do |f|
    path = "#{testdir}/#{f}"
    if File.ftype(path) == "file" && File.basename(f).match(/_test.rb$/)
      load path
    end
  end
end

namespace :example do
  
  desc "An extended generator DSL example."
  task :tarski do
    require 'example/tarski'
  end
  
  desc "Extract base rules from a selector tree."
  task :descope do
    require 'example/descope'
  end
end

