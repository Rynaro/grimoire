# frozen_string_literal: true

require 'pastel'

module Grimoire
  module Infrastructure
    module Rendering
      # TerminalFormatter - Infrastructure Service
      # Provides terminal formatting utilities
      # Single Responsibility: Terminal text formatting
      class TerminalFormatter
        def initialize
          @pastel = Pastel.new
        end

        def format_title(text)
          @pastel.bold.cyan(text)
        end

        def format_subtitle(text)
          @pastel.bold.yellow(text)
        end

        def format_selected(text)
          @pastel.on_blue.white(text)
        end

        def format_dim(text)
          @pastel.dim(text)
        end

        def format_error(text)
          @pastel.red.bold(text)
        end

        def format_success(text)
          @pastel.green.bold(text)
        end

        def format_warning(text)
          @pastel.yellow(text)
        end

        def format_info(text)
          @pastel.cyan(text)
        end

        def format_link(text)
          @pastel.cyan.bold(text)
        end

        def strip_ansi(text)
          text.gsub(/\e\[[0-9;]*m/, '')
        end

        def truncate(text, width)
          stripped = strip_ansi(text)
          return text if stripped.length <= width
          
          text[0...(width - 3)] + '...'
        end

        def pad_right(text, width)
          text.ljust(width)
        end

        def pad_left(text, width)
          text.rjust(width)
        end

        def center(text, width)
          text.center(width)
        end
      end
    end
  end
end
