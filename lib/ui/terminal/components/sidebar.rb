# frozen_string_literal: true

require 'curses'

module Grimoire
  module UI
    module Terminal
      module Components
        # Sidebar Component
        # Single Responsibility: Rendering the sidebar with folders and notes
        # Open/Closed Principle: Extendable for different sidebar styles
        class Sidebar
          include Curses

          SIDEBAR_WIDTH = 30

          def initialize(formatter)
            @formatter = formatter
          end

          def render(window, folders:, notes:, current_folder:, selected_note_index:, scroll_offset:)
            height = window.maxy - 2
            
            render_border(window, height)
            render_header(window)
            render_folders(window, folders, current_folder)
            render_notes(window, notes, selected_note_index, scroll_offset, height)
          end

          def width
            SIDEBAR_WIDTH
          end

          private

          def render_border(window, height)
            window.attron(color_pair(1)) do
              (0...height).each do |i|
                window.setpos(i, SIDEBAR_WIDTH)
                window.addstr('│')
              end
            end
          end

          def render_header(window)
            window.setpos(0, 0)
            window.attron(color_pair(5) | A_BOLD) do
              window.addstr(' ✦ GRIMOIRE'.ljust(SIDEBAR_WIDTH))
            end
          end

          def render_folders(window, folders, current_folder)
            window.setpos(2, 1)
            window.attron(color_pair(2) | A_BOLD) do
              window.addstr('📁 FOLDERS')
            end

            folders.take(5).each_with_index do |folder, idx|
              window.setpos(idx + 3, 2)
              display_name = folder.display_name
              
              if folder == current_folder || folder.to_s == current_folder
                window.attron(color_pair(4) | A_BOLD) do
                  window.addstr("> #{display_name}"[0...(SIDEBAR_WIDTH - 3)])
                end
              else
                window.addstr("  #{display_name}"[0...(SIDEBAR_WIDTH - 3)])
              end
            end
          end

          def render_notes(window, notes, selected_index, scroll_offset, height)
            notes_start = 10
            window.setpos(notes_start, 1)
            window.attron(color_pair(2) | A_BOLD) do
              window.addstr('📝 NOTES')
            end

            return if notes.empty?

            visible_height = height - notes_start - 2
            visible_start = scroll_offset
            visible_end = [visible_start + visible_height, notes.length].min

            notes[visible_start...visible_end].each_with_index do |note, idx|
              actual_idx = visible_start + idx
              window.setpos(notes_start + 1 + idx, 2)
              
              name = note.respond_to?(:name) ? note.name : note[:name]
              
              if actual_idx == selected_index
                window.attron(color_pair(4) | A_BOLD) do
                  window.addstr("> #{name}"[0...(SIDEBAR_WIDTH - 3)])
                end
              else
                window.addstr("  #{name}"[0...(SIDEBAR_WIDTH - 3)])
              end
            end

            # Scroll indicator
            if notes.length > visible_height
              indicator_pos = (visible_start.to_f / notes.length * visible_height).to_i
              window.setpos(notes_start + 1 + indicator_pos, SIDEBAR_WIDTH - 1)
              window.attron(color_pair(1) | A_BOLD) do
                window.addstr('◆')
              end
            end
          end
        end
      end
    end
  end
end
