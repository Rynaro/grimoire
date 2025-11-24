# frozen_string_literal: true

require 'curses'
require 'pastel'
require_relative 'components/sidebar'
require_relative 'components/note_area'
require_relative 'utils/file_manager'
require_relative 'utils/search'

module Grimoire
  class Application
    def initialize(notes_dir = nil)
      @file_manager = Utils::FileManager.new(notes_dir)
      @search = Utils::Search.new(@file_manager)
      @pastel = Pastel.new
      @running = true
      @sidebar_width = 30
      @search_mode = false
      @search_query = ''
      @search_results = []
    end

    def run
      Curses.init_screen
      Curses.cbreak
      Curses.noecho
      Curses.curs_set(0) # Hide cursor initially
      Curses.start_color
      Curses.use_default_colors

      setup_windows
      main_loop
    ensure
      Curses.close_screen
    end

    def setup_windows
      screen_height = Curses.lines
      screen_width = Curses.cols

      # Sidebar window
      @sidebar_win = Curses::Window.new(screen_height, @sidebar_width, 0, 0)
      @sidebar = Components::Sidebar.new(@sidebar_win, @file_manager)

      # Note area window
      note_area_width = screen_width - @sidebar_width
      @note_area_win = Curses::Window.new(screen_height, note_area_width, 0, @sidebar_width)
      @note_area = Components::NoteArea.new(@note_area_win, @file_manager)

      # Status bar window (at bottom)
      @status_win = Curses::Window.new(1, screen_width, screen_height - 1, 0)
    end

    def main_loop
      render_all

      while @running
        ch = @sidebar_win.getch

        if @search_mode
          handle_search_input(ch)
        elsif @note_area.mode == Components::NoteArea::MODE_EDIT
          handle_edit_mode(ch)
        else
          handle_normal_mode(ch)
        end

        render_all
      end
    end

    def handle_normal_mode(ch)
      case ch
      when 'q', 'Q'
        @running = false
      when Curses::KEY_UP, 'k'
        @sidebar.move_up
        load_selected_note
      when Curses::KEY_DOWN, 'j'
        @sidebar.move_down
        load_selected_note
      when 'e', 'E'
        @note_area.set_mode(Components::NoteArea::MODE_EDIT)
        Curses.curs_set(1) # Show cursor
      when 'v', 'V'
        @note_area.set_mode(Components::NoteArea::MODE_VIEW)
        Curses.curs_set(0) # Hide cursor
      when 'n', 'N'
        create_new_note
      when 'd', 'D'
        delete_selected_item
      when '/'
        start_search
      when Curses::KEY_PPAGE
        @note_area.scroll_up
      when Curses::KEY_NPAGE
        @note_area.scroll_down
      when Curses::KEY_RESIZE
        handle_resize
      end
    end

    def handle_edit_mode(ch)
      case ch
      when 27 # ESC
        @note_area.set_mode(Components::NoteArea::MODE_VIEW)
        Curses.curs_set(0)
      when Curses::KEY_CTRL_S, 19 # Ctrl+S
        @note_area.save
        @sidebar.refresh_items
      when Curses::KEY_RESIZE
        handle_resize
      else
        @note_area.handle_edit_input(ch)
      end
    end

    def handle_search_input(ch)
      case ch
      when 27 # ESC
        @search_mode = false
        @search_query = ''
        @sidebar.refresh_items
      when 10, 13 # Enter
        select_search_result
      when 127, 8 # Backspace
        @search_query = @search_query[0..-2] if @search_query.length > 0
        perform_search
      when Curses::KEY_UP
        @sidebar.move_up
      when Curses::KEY_DOWN
        @sidebar.move_down
      when Curses::KEY_RESIZE
        handle_resize
      else
        if ch >= 32 && ch < 127
          @search_query += ch.chr
          perform_search
        end
      end
    end

    def start_search
      @search_mode = true
      @search_query = ''
      @search_results = []
    end

    def perform_search
      return if @search_query.empty?

      @search_results = @search.search_content(@search_query)
      @sidebar.items = @search_results.map do |result|
        {
          type: :note,
          name: result[:name],
          path: result[:path],
          folder: result[:folder],
          matches: result[:matches]
        }
      end
      @sidebar.selected_index = 0 if @sidebar.items.length > 0
      @sidebar.scroll_offset = 0
    end

    def select_search_result
      item = @sidebar.selected_item
      return unless item && item[:path]

      @search_mode = false
      @search_query = ''
      @sidebar.refresh_items
      @note_area.load_note(item[:path])
    end

    def load_selected_note
      item = @sidebar.selected_item
      return unless item && item[:type] == :note && item[:path]

      @note_area.load_note(item[:path])
    end

    def create_new_note
      # Simple prompt - in a real app, you'd want a proper input dialog
      @status_win.clear
      @status_win.addstr('Enter note name (or ESC to cancel): ')
      @status_win.refresh
      Curses.echo
      Curses.curs_set(1)

      name = ''
      loop do
        ch = @status_win.getch
        case ch
        when 27 # ESC
          name = nil
          break
        when 10, 13 # Enter
          break
        when 127, 8 # Backspace
          name = name[0..-2] if name.length > 0
        else
          name += ch.chr if ch >= 32 && ch < 127
        end
        @status_win.setpos(0, 0)
        @status_win.clrtoeol
        @status_win.addstr("Enter note name (or ESC to cancel): #{name}")
        @status_win.refresh
      end

      Curses.noecho
      Curses.curs_set(0)

      if name && !name.empty?
        path = @file_manager.create_note(name)
        @sidebar.refresh_items
        @note_area.load_note(path)
        @note_area.set_mode(Components::NoteArea::MODE_EDIT)
        Curses.curs_set(1)
      end
    end

    def delete_selected_item
      item = @sidebar.selected_item
      return unless item

      # Simple confirmation
      @status_win.clear
      @status_win.addstr("Delete #{item[:name]}? (y/n): ")
      @status_win.refresh
      Curses.echo
      Curses.curs_set(1)

      ch = @status_win.getch
      Curses.noecho
      Curses.curs_set(0)

      if ch.chr.downcase == 'y'
        if item[:type] == :folder
          @file_manager.delete_folder(item[:path])
        else
          @file_manager.delete_note(item[:path])
        end
        @sidebar.refresh_items
        @note_area.load_note(nil) if item[:type] == :note
      end
    end

    def handle_resize
      screen_height = Curses.lines
      screen_width = Curses.cols

      @sidebar_win.resize(screen_height, @sidebar_width)
      @note_area_win.resize(screen_height, screen_width - @sidebar_width)
      @note_area_win.mvwin(0, @sidebar_width)
      @status_win.resize(1, screen_width)
      @status_win.mvwin(screen_height - 1, 0)
    end

    def render_all
      @sidebar.render
      @note_area.render
      render_status_bar
    end

    def render_status_bar
      @status_win.clear
      
      if @search_mode
        status = "Search: #{@search_query}_"
      elsif @note_area.mode == Components::NoteArea::MODE_EDIT
        status = '[EDIT MODE] Press ESC to exit, Ctrl+S to save'
      else
        status = 'q: quit | e: edit | n: new | d: delete | /: search | ↑↓: navigate'
      end

      @status_win.addstr(status[0, @status_win.maxx - 1])
      @status_win.refresh
    end
  end
end
