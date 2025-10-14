# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = true
end

task default: :test

begin
  require "bundler/gem_tasks"
rescue LoadError
  # bundler not available; build tasks will be unavailable
end


