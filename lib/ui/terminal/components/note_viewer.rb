# frozen_string_literal: true

require 'curses'

module Grimoire
  module UI
    module Terminal
      module Components
        # NoteViewer Component
        # Single Responsibility: Displaying note content
        class NoteViewer
          include Curses

          def initialize(markdown_renderer, formatter)
            @markdown_renderer = markdown_renderer
            @formatter = formatter
          end

          def render(window, note:, scroll_offset:, start_x:, width:, height:)
            render_header(window, note, start_x, width)
            render_content(window, note, scroll_offset, start_x, width, height)
          end

          def render_empty(window, start_x, width, height)
            window.setpos(0, start_x)
            window.attron(color_pair(1) | A_BOLD) do
              window.addstr(" No Note Selected ".ljust(width))
            end

            message = "Select a note from the sidebar to view it"
            window.setpos(height / 2, start_x + (width - message.length) / 2)
            window.attron(color_pair(3)) do
              window.addstr(message)
            end
          end

          private

          def render_header(window, note, start_x, width)
            window.setpos(0, start_x)
            window.attron(color_pair(1) | A_BOLD) do
              title = " #{note.name} "
              window.addstr(title[0...width])
            end
          end

          def render_content(window, note, scroll_offset, start_x, width, height)
            rendered = @markdown_renderer.render(note.content)
            lines_array = rendered.split("\n")
            
            visible_lines = lines_array[scroll_offset, height - 1] || []
            
            visible_lines.each_with_index do |line, idx|
              window.setpos(idx + 1, start_x)
              clean_line = @formatter.strip_ansi(line)[0...width]
              window.addstr(clean_line)
            end

            render_scroll_indicator(window, lines_array.length, scroll_offset, height, width, start_x)
          end

          def render_scroll_indicator(window, total_lines, offset, height, width, start_x)
            return if total_lines <= height - 1

            progress = (offset * 100 / [total_lines - height + 1, 1].max)
            window.setpos(height - 1, start_x + width - 10)
            window.attron(color_pair(1)) do
              window.addstr(" [#{progress}%] ")
            end
          end
        end
      end
    end
  end
end
