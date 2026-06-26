# frozen_string_literal: true

require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task(:spec) { abort "Run `bundle install` first." }
end

task :changelog_check do
  changelog     = File.read("CHANGELOG.md")
  unreleased    = changelog[/## \[Unreleased\](.*?)## \[/m, 1] || ""
  headings_only = unreleased.gsub(/###.*/, "").strip
  abort "CHANGELOG.md [Unreleased] section is empty. Add entries before releasing." if headings_only.empty?
  puts "CHANGELOG.md looks good."
end

task :clean_tree do
  abort "Working tree is dirty. Commit or stash changes before releasing." unless `git status --porcelain`.strip.empty?
end

desc "Run full preflight: specs + changelog check + clean tree"
task preflight: %i[spec changelog_check clean_tree]

desc "Cut a release — usage: rake cut_release[minor]"
task :cut_release, [:bump] do |_, args|
  sh "bin/release #{args[:bump] || 'patch'}"
end

task default: :spec
