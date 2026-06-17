require "rake/testtask"
require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task(:spec) { abort "Run `bundle install` first." }
end

task default: :spec
