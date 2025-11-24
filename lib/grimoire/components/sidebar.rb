# frozen_string_literal: true

require 'curses'
require 'pastel'

module Grimoire
  module Components
    class Sidebar
      attr_reader :window, :selected_index, :items, :scroll_offset

      def initialize(window, search_service)
        @window = window
        @search_service = search_service
        @pastel = Pastel.new
        @selected_index = 0
        @scroll_offset = 0
        @items = []
        refresh_items
      end

      def refresh_items
        @items = @search_service.list_all_items
        @selected_index = 0 if @selected_index >= @items.length
        @scroll_offset = 0 if @scroll_offset >= @items.length
      end

      def width
        @window.maxx
      end

      def height
        @window.maxy
      end

      def render
        @window.clear
        @window.box('|', '-')

        # Title
        title = ' Notes '
        @window.setpos(0, (width - title.length) / 2)
        @window.attron(Curses::A_BOLD) do
          @window.addstr(title)
        end

        # Calculate visible range
        visible_height = height - 2
        start_idx = [@scroll_offset, @selected_index - visible_height / 2].max
        end_idx = [start_idx + visible_height, @items.length].min

        # Render items
        (start_idx...end_idx).each_with_index do |item_idx, display_idx|
          item = @items[item_idx]
          y = display_idx + 1
          
          if item_idx == @selected_index
            @window.attron(Curses::A_REVERSE) do
              render_item(y, item, item_idx == @selected_index)
            end
          else
            render_item(y, item, false)
          end
        end

        @window.refresh
      end

      def render_item(y, item, selected)
        @window.setpos(y, 1)
        
        if item[:type] == :folder
          icon = selected ? '📁' : '📂'
          name = item[:name]
          display = "#{icon} #{name}"
        else
          icon = selected ? '📄' : '📝'
          name = item[:name]
          folder_indicator = item[:folder] ? " [#{item[:folder]}]" : ''
          display = "#{icon} #{name}#{folder_indicator}"
        end

        # Truncate if too long
        max_width = width - 2
        display = display[0, max_width] if display.length > max_width
        
        @window.addstr(display)
      end

      def move_up
        if @selected_index > 0
          @selected_index -= 1
          adjust_scroll
        end
      end

      def move_down
        if @selected_index < @items.length - 1
          @selected_index += 1
          adjust_scroll
        end
      end

      def adjust_scroll
        visible_height = height - 2
        if @selected_index < @scroll_offset
          @scroll_offset = @selected_index
        elsif @selected_index >= @scroll_offset + visible_height
          @scroll_offset = @selected_index - visible_height + 1
        end
      end

      def selected_item
        @items[@selected_index]
      end

      def select_item(index)
        @selected_index = [[index, 0].max, @items.length - 1].min
        adjust_scroll
      end
    end
  end
end
