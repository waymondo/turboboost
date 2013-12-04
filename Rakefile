# encoding: UTF-8

require 'bundler/gem_tasks'
require 'rake/testtask'

desc 'Run tests for Turboboost.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

# Make test the default task.
task :default => :test
