#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/ui/terminal/application'

begin
  Grimoire::UI::Terminal::Application.new.run
rescue Interrupt
  puts "\n\n👋 Goodbye! Your notes are safe in your filesystem."
  exit(0)
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit(1)
end
