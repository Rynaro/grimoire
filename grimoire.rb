#!/usr/bin/env ruby
# frozen_string_literal: true

# Check if running in proper terminal
unless STDIN.tty?
  puts "❌ Error: Grimoire requires an interactive terminal (TTY)"
  puts "Run with: docker run -it grimoire"
  exit(1)
end

# Display startup message
puts "✦ Starting Grimoire..."
puts "   Loading components..."
sleep 0.5

require_relative 'lib/ui/terminal/application'

begin
  Grimoire::UI::Terminal::Application.new.run
rescue Interrupt
  puts "\n\n👋 Goodbye! Your notes are safe in your filesystem."
  exit(0)
rescue LoadError => e
  puts "\n❌ Dependency Error: #{e.message}"
  puts "\nTry running: bundle install"
  exit(1)
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts "\nDebug information:"
  puts "  Ruby: #{RUBY_VERSION}"
  puts "  TERM: #{ENV['TERM']}"
  puts "  TTY: #{STDIN.tty?}"
  puts "\nStack trace:" if ENV['DEBUG']
  puts e.backtrace.join("\n") if ENV['DEBUG']
  exit(1)
end
