# frozen_string_literal: true

require 'curses'
require 'pastel'
require_relative '../utils/markdown_renderer'

module Grimoire
  module Components
    class NoteArea
      MODE_VIEW = :view
      MODE_EDIT = :edit

      attr_reader :window, :mode, :content, :file_path, :scroll_offset, :cursor_pos

      def initialize(window, file_manager)
        @window = window
        @file_manager = file_manager
        @pastel = Pastel.new
        @markdown_renderer = Utils::MarkdownRenderer.new
        @mode = MODE_VIEW
        @content = ''
        @file_path = nil
        @scroll_offset = 0
        @cursor_pos = { x: 0, y: 0 }
        @edit_buffer = []
        @edit_cursor = { x: 0, y: 0 }
      end

      def width
        @window.maxx
      end

      def height
        @window.maxy
      end

      def load_note(path)
        return unless path && File.exist?(path)

        @file_path = path
        @content = @file_manager.read_note(path) || ''
        @edit_buffer = @content.lines.map(&:chomp)
        @scroll_offset = 0
        @cursor_pos = { x: 0, y: 0 }
        @edit_cursor = { x: 0, y: 0 }
        @mode = MODE_VIEW
      end

      def set_mode(new_mode)
        @mode = new_mode
        if @mode == MODE_EDIT && @edit_buffer.empty?
          @edit_buffer = @content.lines.map(&:chomp)
        end
      end

      def render
        @window.clear
        @window.box('|', '-')

        # Title bar
        title = mode_title
        @window.setpos(0, 1)
        @window.attron(Curses::A_BOLD) do
          @window.addstr(title)
        end

        if @mode == MODE_VIEW
          render_view
        else
          render_edit
        end

        @window.refresh
      end

      def mode_title
        if @file_path
          name = File.basename(@file_path, '.md')
          mode_indicator = @mode == MODE_VIEW ? '[VIEW]' : '[EDIT]'
          "#{mode_indicator} #{name}"
        else
          '[No note selected]'
        end
      end

      def render_view
        return if @content.empty?

        lines = wrap_text(@content, width - 2)
        visible_height = height - 2

        lines[@scroll_offset, visible_height]&.each_with_index do |line, idx|
          @window.setpos(idx + 1, 1)
          render_line_with_links(line)
        end
      end

      def render_edit
        visible_height = height - 2
        edit_scroll = [@edit_cursor[:y] - visible_height / 2, 0].max
        start_line = edit_scroll
        end_line = [start_line + visible_height, @edit_buffer.length].min

        (start_line...end_line).each_with_index do |line_idx, display_idx|
          @window.setpos(display_idx + 1, 1)
          line = @edit_buffer[line_idx] || ''
          
          # Highlight cursor line
          if line_idx == @edit_cursor[:y]
            @window.attron(Curses::A_REVERSE) do
              display_line = line[0, width - 2] || ''
              @window.addstr(display_line)
            end
          else
            display_line = line[0, width - 2] || ''
            @window.addstr(display_line)
          end
        end

        # Position cursor
        if @edit_cursor[:y] >= start_line && @edit_cursor[:y] < end_line
          cursor_y = @edit_cursor[:y] - start_line + 1
          cursor_x = [@edit_cursor[:x] + 1, width - 1].min
          @window.setpos(cursor_y, cursor_x)
        end
      end

      def render_line_with_links(line)
        # Simple rendering - highlight markdown links and wiki links
        # For a more sophisticated version, we'd parse the markdown properly
        line.scan(/(\[\[[^\]]+\]\]|\[[^\]]+\]\([^)]+\))/) do |match|
          # Highlight links
        end
        @window.addstr(line[0, width - 2] || '')
      end

      def wrap_text(text, max_width)
        lines = []
        text.lines.each do |line|
          if line.length <= max_width
            lines << line.chomp
          else
            line.chomp.scan(/.{1,#{max_width}}/) do |chunk|
              lines << chunk
            end
          end
        end
        lines
      end

      def scroll_up
        @scroll_offset = [@scroll_offset - 1, 0].max if @mode == MODE_VIEW
      end

      def scroll_down
        max_scroll = [wrap_text(@content, width - 2).length - (height - 2), 0].max
        @scroll_offset = [@scroll_offset + 1, max_scroll].min if @mode == MODE_VIEW
      end

      def save
        return unless @file_path && @mode == MODE_EDIT

        @content = @edit_buffer.join("\n")
        @file_manager.write_note(@file_path, @content)
        @mode = MODE_VIEW
      end

      def handle_edit_input(ch)
        case ch
        when 10, 13 # Enter
          insert_newline
        when 127, 8 # Backspace
          handle_backspace
        when Curses::KEY_UP
          move_cursor_up
        when Curses::KEY_DOWN
          move_cursor_down
        when Curses::KEY_LEFT
          move_cursor_left
        when Curses::KEY_RIGHT
          move_cursor_right
        when 9 # Tab
          insert_tab
        else
          insert_char(ch) if ch >= 32 && ch < 127
        end
      end

      def insert_char(ch)
        line = @edit_buffer[@edit_cursor[:y]] || ''
        x = @edit_cursor[:x]
        @edit_buffer[@edit_cursor[:y]] = line[0, x] + ch.chr + line[x..-1].to_s
        @edit_cursor[:x] += 1
      end

      def insert_newline
        line = @edit_buffer[@edit_cursor[:y]] || ''
        x = @edit_cursor[:x]
        @edit_buffer[@edit_cursor[:y]] = line[0, x]
        @edit_buffer.insert(@edit_cursor[:y] + 1, line[x..-1].to_s)
        @edit_cursor[:y] += 1
        @edit_cursor[:x] = 0
      end

      def handle_backspace
        if @edit_cursor[:x] > 0
          line = @edit_buffer[@edit_cursor[:y]] || ''
          x = @edit_cursor[:x]
          @edit_buffer[@edit_cursor[:y]] = line[0, x - 1] + line[x..-1].to_s
          @edit_cursor[:x] -= 1
        elsif @edit_cursor[:y] > 0
          # Merge with previous line
          prev_line = @edit_buffer[@edit_cursor[:y] - 1] || ''
          current_line = @edit_buffer[@edit_cursor[:y]] || ''
          @edit_buffer[@edit_cursor[:y] - 1] = prev_line + current_line
          @edit_buffer.delete_at(@edit_cursor[:y])
          @edit_cursor[:y] -= 1
          @edit_cursor[:x] = prev_line.length
        end
      end

      def move_cursor_up
        @edit_cursor[:y] = [@edit_cursor[:y] - 1, 0].max
        adjust_cursor_x
      end

      def move_cursor_down
        @edit_cursor[:y] = [@edit_cursor[:y] + 1, @edit_buffer.length - 1].min
        adjust_cursor_x
      end

      def move_cursor_left
        @edit_cursor[:x] = [@edit_cursor[:x] - 1, 0].max
      end

      def move_cursor_right
        line = @edit_buffer[@edit_cursor[:y]] || ''
        @edit_cursor[:x] = [@edit_cursor[:x] + 1, line.length].min
      end

      def adjust_cursor_x
        line = @edit_buffer[@edit_cursor[:y]] || ''
        @edit_cursor[:x] = [@edit_cursor[:x], line.length].min
      end

      def insert_tab
        2.times { insert_char(32) } # Insert 2 spaces
      end
    end
  end
end
