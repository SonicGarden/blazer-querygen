# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[test rubocop]

namespace :sandbox do
  desc "Start the sandbox Rails app for manual testing"
  task :server do
    exec "bin/sandbox"
  end

  desc "Reset the sandbox app database"
  task :reset do
    Dir.chdir("test/sandbox") do
      system("bundle exec rails db:drop db:create db:migrate db:seed")
    end
  end
end
