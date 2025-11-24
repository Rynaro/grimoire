# frozen_string_literal: true

require 'curses'

module Grimoire
  module UI
    module Terminal
      module Components
        # HelpOverlay Component
        # Single Responsibility: Displaying help information
        class HelpOverlay
          include Curses

          def initialize(formatter)
            @formatter = formatter
          end

          def render(window)
            height = window.maxy
            width = window.maxx
            
            help_height = 20
            help_width = 60
            start_y = (height - help_height) / 2
            start_x = (width - help_width) / 2

            render_background(window, start_y, start_x, help_height, help_width)
            render_border(window, start_y, start_x, help_height, help_width)
            render_content(window, start_y, start_x, help_width)
          end

          private

          def render_background(window, start_y, start_x, height, width)
            (start_y...start_y + height).each do |y|
              window.setpos(y, start_x)
              window.attron(color_pair(5)) do
                window.addstr(' ' * width)
              end
            end
          end

          def render_border(window, start_y, start_x, height, width)
            window.attron(color_pair(5) | A_BOLD) do
              window.setpos(start_y, start_x)
              window.addstr('┌' + '─' * (width - 2) + '┐')
              
              (start_y + 1...start_y + height - 1).each do |y|
                window.setpos(y, start_x)
                window.addstr('│')
                window.setpos(y, start_x + width - 1)
                window.addstr('│')
              end
              
              window.setpos(start_y + height - 1, start_x)
              window.addstr('└' + '─' * (width - 2) + '┘')
            end
          end

          def render_content(window, start_y, start_x, width)
            help_text.each_with_index do |line, idx|
              window.setpos(start_y + 1 + idx, start_x + 2)
              window.attron(color_pair(5)) do
                window.addstr(line[0...(width - 4)])
              end
            end
          end

          def help_text
            [
              '  GRIMOIRE - KEYBOARD SHORTCUTS',
              '',
              '  Navigation:',
              '    j/k or ↓/↑    - Move selection',
              '    h/l or ←/→    - Switch folder/note',
              '    Space or PgDn - Scroll down',
              '    b or PgUp     - Scroll up',
              '',
              '  Actions:',
              '    Enter         - Open note',
              '    e             - Edit note',
              '    n             - New note',
              '    d             - Delete note',
              '    /             - Search',
              '    s             - Save (in edit mode)',
              '',
              '  Other:',
              '    ?             - Toggle this help',
              '    q             - Quit'
            ]
          end
        end
      end
    end
  end
end
