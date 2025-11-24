# frozen_string_literal: true

require "bundler/setup"
require "rspec"
require "fileutils"
require "tmpdir"

require_relative "../lib/grimoire"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after do
    Thread.list.each do |thread|
      next if [Thread.main].include?(thread) || !thread.alive?

      thread.kill
    end
  end
end
