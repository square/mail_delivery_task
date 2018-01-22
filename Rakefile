# frozen_string_literal: true
require 'bundler/setup'
require 'sq/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new

require 'sq/lint/rake_task'
Sq::Lint::RakeTask.new

task default: %w(spec rubocop sq:lint:gem)
