# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "cucumber/rake/task"
require "rubocop/rake_task"
require "rake/dsl_definition"
require "rake"
require "rspec"

RSpec::Core::RakeTask.new(:spec) do |rspec|
  rspec.pattern = FileList["spec/**/*_spec.rb"]
end

Cucumber::Rake::Task.new(:features)

RuboCop::RakeTask.new

task default: %i[rubocop features spec]

desc "open an irb session preloaded with this gem"
task :console do
  sh "irb -I lib -I extra -r dwc_archive.rb"
end
