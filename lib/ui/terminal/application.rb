# frozen_string_literal: true

require 'curses'
require_relative '../../container'
require_relative 'components/sidebar'
require_relative 'components/note_viewer'
require_relative 'components/note_editor'
require_relative 'components/status_bar'
require_relative 'components/help_overlay'

module Grimoire
  module UI
    module Terminal
      # Application Controller
      # Single Responsibility: Coordinating UI components and handling user input
      # Depends on use cases (application layer), not domain or infrastructure directly
      class Application
        include Curses
        include Import[
          :list_notes_use_case,
          :get_note_use_case,
          :create_note_use_case,
          :update_note_use_case,
          :delete_note_use_case,
          :search_notes_use_case,
          :markdown_renderer,
          :terminal_formatter
        ]

        def initialize(**deps)
          super
          @current_folder = Domain::ValueObjects::FolderPath.all_notes
          @selected_note_index = 0
          @current_note = nil
          @mode = :view
          @scroll_offset = 0
          @sidebar_scroll = 0
          @help_visible = false
          @edit_buffer = []
          @edit_cursor_line = 0

          # Initialize UI components
          @sidebar = Components::Sidebar.new(terminal_formatter)
          @note_viewer = Components::NoteViewer.new(markdown_renderer, terminal_formatter)
          @note_editor = Components::NoteEditor.new(terminal_formatter)
          @status_bar = Components::StatusBar.new(terminal_formatter)
          @help_overlay = Components::HelpOverlay.new(terminal_formatter)
        end

        def run
          init_screen
          start_color
          curs_set(0)
          noecho
          stdscr.keypad(true)
          
          init_colors
          
          begin
            render_ui
            handle_input
          ensure
            close_screen
          end
        end

        private

        def init_colors
          init_pair(1, COLOR_CYAN, COLOR_BLACK)
          init_pair(2, COLOR_YELLOW, COLOR_BLACK)
          init_pair(3, COLOR_GREEN, COLOR_BLACK)
          init_pair(4, COLOR_WHITE, COLOR_BLUE)
          init_pair(5, COLOR_BLACK, COLOR_CYAN)
          init_pair(6, COLOR_RED, COLOR_BLACK)
          init_pair(7, COLOR_MAGENTA, COLOR_BLACK)
        end

        def render_ui
          stdscr.clear
          
          render_main_layout
          @help_overlay.render(stdscr) if @help_visible
          
          stdscr.refresh
        end

        def render_main_layout
          notes = get_current_notes
          folders = list_notes_use_case.folders

          # Render sidebar
          @sidebar.render(
            stdscr,
            folders: folders,
            notes: notes,
            current_folder: @current_folder,
            selected_note_index: @selected_note_index,
            scroll_offset: @sidebar_scroll
          )

          # Render main area
          start_x = @sidebar.width + 1
          width = cols - @sidebar.width - 2
          height = lines - 2

          if @current_note
            if @mode == :edit
              @note_editor.render(
                stdscr,
                note: @current_note,
                buffer: @edit_buffer,
                cursor_line: @edit_cursor_line,
                scroll_offset: @scroll_offset,
                start_x: start_x,
                width: width,
                height: height
              )
            else
              @note_viewer.render(
                stdscr,
                note: @current_note,
                scroll_offset: @scroll_offset,
                start_x: start_x,
                width: width,
                height: height
              )
            end
          else
            @note_viewer.render_empty(stdscr, start_x, width, height)
          end

          # Render status bar
          @status_bar.render(
            stdscr,
            mode: @mode,
            note_count: notes.length,
            current_folder: @current_folder
          )
        end

        def handle_input
          loop do
            char = stdscr.getch
            
            case @mode
            when :view
              handle_view_input(char)
            when :edit
              handle_edit_input(char)
            end

            render_ui
          end
        end

        def handle_view_input(char)
          case char
          when 'q', 'Q'
            exit(0)
          when '?'
            @help_visible = !@help_visible
          when 'j', KEY_DOWN
            move_selection(1)
          when 'k', KEY_UP
            move_selection(-1)
          when ' ', KEY_NPAGE
            @scroll_offset += 10
          when 'b', KEY_PPAGE
            @scroll_offset = [@scroll_offset - 10, 0].max
          when 'e'
            enter_edit_mode if @current_note
          when 'n'
            create_new_note
          when 'd'
            delete_current_note if @current_note
          when '/', 's'
            # Simplified search - in full implementation would open search UI
            @scroll_offset = 0
          when 10, KEY_ENTER, 13
            open_selected_note
          end
        end

        def handle_edit_input(char)
          case char
          when 'q', 27 # ESC
            @mode = :view
            @scroll_offset = 0
          when 's'
            save_note
            @mode = :view
          when 'j', KEY_DOWN
            @edit_cursor_line = [@edit_cursor_line + 1, @edit_buffer.length - 1].min
            adjust_edit_scroll
          when 'k', KEY_UP
            @edit_cursor_line = [@edit_cursor_line - 1, 0].max
            adjust_edit_scroll
          when 'i'
            @edit_buffer.insert(@edit_cursor_line + 1, '')
            @edit_cursor_line += 1
          when 'x'
            @edit_buffer.delete_at(@edit_cursor_line) if @edit_buffer.length > 1
          end
        end

        def move_selection(delta)
          notes = get_current_notes
          return if notes.empty?

          @selected_note_index = (@selected_note_index + delta) % notes.length
          adjust_sidebar_scroll
        end

        def adjust_sidebar_scroll
          height = lines - 2
          folders = list_notes_use_case.folders
          notes_start = 10
          visible_height = height - notes_start - 2

          if @selected_note_index < @sidebar_scroll
            @sidebar_scroll = @selected_note_index
          elsif @selected_note_index >= @sidebar_scroll + visible_height
            @sidebar_scroll = @selected_note_index - visible_height + 1
          end
        end

        def adjust_edit_scroll
          height = lines - 2
          
          if @edit_cursor_line < @scroll_offset
            @scroll_offset = @edit_cursor_line
          elsif @edit_cursor_line >= @scroll_offset + height - 2
            @scroll_offset = @edit_cursor_line - height + 3
          end
        end

        def open_selected_note
          notes = get_current_notes
          return if notes.empty?

          selected_note = notes[@selected_note_index]
          @current_note = get_note_use_case.call(path: selected_note.path)
          @scroll_offset = 0
        end

        def enter_edit_mode
          return unless @current_note

          @edit_buffer = @current_note.content.lines
          @edit_cursor_line = 0
          @scroll_offset = 0
          @mode = :edit
        end

        def save_note
          return unless @current_note

          content = @edit_buffer.join("\n")
          update_note_use_case.call(path: @current_note.path, content: content)
          
          # Reload note
          @current_note = get_note_use_case.call(path: @current_note.path)
        end

        def create_new_note
          timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
          name = "note_#{timestamp}"
          
          begin
            note = create_note_use_case.call(name: name)
            @current_note = note
            @selected_note_index = 0
            @sidebar_scroll = 0
          rescue => e
            # In a full implementation, would show error message
            warn "Error creating note: #{e.message}"
          end
        end

        def delete_current_note
          return unless @current_note

          begin
            delete_note_use_case.call(path: @current_note.path)
            @current_note = nil
            @selected_note_index = 0
            @sidebar_scroll = 0
          rescue => e
            warn "Error deleting note: #{e.message}"
          end
        end

        def get_current_notes
          folder = @current_folder.all_notes? ? nil : @current_folder
          list_notes_use_case.call(folder: folder)
        end
      end
    end
  end
end
