# frozen_string_literal: true

require 'curses'

module Grimoire
  module UI
    module Terminal
      module Components
        # NoteEditor Component
        # Single Responsibility: Editing note content
        class NoteEditor
          include Curses

          def initialize(formatter)
            @formatter = formatter
          end

          def render(window, note:, buffer:, cursor_line:, scroll_offset:, start_x:, width:, height:)
            render_header(window, note, start_x, width)
            render_edit_area(window, buffer, cursor_line, scroll_offset, start_x, width, height)
            render_status(window, cursor_line, buffer.length, height, start_x, width)
          end

          private

          def render_header(window, note, start_x, width)
            window.setpos(0, start_x)
            window.attron(color_pair(6) | A_BOLD) do
              title = " EDITING: #{note.name} "
              window.addstr(title[0...width])
            end
          end

          def render_edit_area(window, buffer, cursor_line, scroll_offset, start_x, width, height)
            visible_lines = buffer[scroll_offset, height - 2] || []
            
            visible_lines.each_with_index do |line, idx|
              window.setpos(idx + 1, start_x)
              actual_line = scroll_offset + idx
              
              if actual_line == cursor_line
                window.attron(color_pair(4)) do
                  text = "> #{line}"[0...width]
                  window.addstr(text)
                end
              else
                text = "  #{line}"[0...width]
                window.addstr(text)
              end
            end
          end

          def render_status(window, cursor_line, total_lines, height, start_x, width)
            window.setpos(height - 1, start_x + width - 20)
            window.attron(color_pair(6)) do
              window.addstr(" L:#{cursor_line + 1}/#{total_lines} ")
            end
          end
        end
      end
    end
  end
end
