# frozen_string_literal: true

require 'curses'

module Grimoire
  module UI
    module Terminal
      module Components
        # StatusBar Component
        # Single Responsibility: Displaying status information
        class StatusBar
          include Curses

          def initialize(formatter)
            @formatter = formatter
          end

          def render(window, mode:, note_count:, current_folder:)
            height = window.maxy
            width = window.maxx

            render_separator(window, height, width)
            render_status(window, mode, note_count, current_folder, height, width)
            render_help_hint(window, height, width)
          end

          private

          def render_separator(window, height, width)
            window.setpos(height - 2, 0)
            window.attron(color_pair(1)) do
              window.addstr('─' * width)
            end
          end

          def render_status(window, mode, note_count, current_folder, height, width)
            window.setpos(height - 1, 0)
            window.attron(color_pair(1)) do
              mode_str = case mode
                        when :edit then '[EDIT]'
                        when :command then '[COMMAND]'
                        else '[VIEW]'
                        end
              
              folder_name = current_folder.respond_to?(:display_name) ? 
                           current_folder.display_name : 
                           current_folder.to_s
              
              status = " #{mode_str} Notes: #{note_count} Folder: #{folder_name} "
              window.addstr(status.ljust(width))
            end
          end

          def render_help_hint(window, height, width)
            window.setpos(height - 1, width - 25)
            window.attron(color_pair(3)) do
              window.addstr(' Press ? for help ')
            end
          end
        end
      end
    end
  end
end
