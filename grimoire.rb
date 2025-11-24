#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/ui/application'

begin
  Grimoire::UI::Application.new.run
rescue Interrupt
  puts "\n\n👋 Goodbye! Your notes are safe in your filesystem."
  exit(0)
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace
  exit(1)
end
