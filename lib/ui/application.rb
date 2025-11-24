# frozen_string_literal: true

require 'curses'
require 'pastel'
require_relative '../core/notes_manager'
require_relative '../renderers/markdown_renderer'

module Grimoire
  module UI
    # Main application controller
    class Application
      include Curses

      SIDEBAR_WIDTH = 30
      
      attr_reader :notes_manager, :pastel

      def initialize
        @notes_manager = Core::NotesManager.new
        @pastel = Pastel.new
        @current_folder = 'All Notes'
        @selected_note_index = 0
        @current_note = nil
        @mode = :view # :view, :edit, :command
        @scroll_offset = 0
        @edit_buffer = []
        @edit_cursor_line = 0
        @sidebar_scroll = 0
        @help_visible = false
      end

      def run
        init_screen
        start_color
        curs_set(0) # Hide cursor in view mode
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
        
        render_sidebar
        render_main_area
        render_status_bar
        render_help if @help_visible
        
        stdscr.refresh
      end

      def render_sidebar
        height = lines - 2
        
        # Sidebar border
        stdscr.attron(color_pair(1)) do
          (0...height).each do |i|
            stdscr.setpos(i, SIDEBAR_WIDTH)
            stdscr.addstr('│')
          end
        end

        # Header
        stdscr.setpos(0, 0)
        stdscr.attron(color_pair(5) | A_BOLD) do
          stdscr.addstr(' ✦ GRIMOIRE'.ljust(SIDEBAR_WIDTH))
        end

        # Folders section
        stdscr.setpos(2, 1)
        stdscr.attron(color_pair(2) | A_BOLD) do
          stdscr.addstr('📁 FOLDERS')
        end

        folders = @notes_manager.list_folders
        folders.each_with_index do |folder, idx|
          break if idx + 3 >= height - 10
          
          stdscr.setpos(idx + 3, 2)
          if folder == @current_folder
            stdscr.attron(color_pair(4) | A_BOLD) do
              stdscr.addstr("> #{folder}"[0...(SIDEBAR_WIDTH - 3)])
            end
          else
            stdscr.addstr("  #{folder}"[0...(SIDEBAR_WIDTH - 3)])
          end
        end

        # Notes section
        notes_start = [folders.length + 5, 10].max
        stdscr.setpos(notes_start, 1)
        stdscr.attron(color_pair(2) | A_BOLD) do
          stdscr.addstr('📝 NOTES')
        end

        notes = get_current_notes
        visible_start = @sidebar_scroll
        visible_end = [visible_start + (height - notes_start - 2), notes.length].min
        
        notes[visible_start...visible_end].each_with_index do |note, idx|
          actual_idx = visible_start + idx
          stdscr.setpos(notes_start + 1 + idx, 2)
          
          if actual_idx == @selected_note_index
            stdscr.attron(color_pair(4) | A_BOLD) do
              stdscr.addstr("> #{note[:name]}"[0...(SIDEBAR_WIDTH - 3)])
            end
          else
            stdscr.addstr("  #{note[:name]}"[0...(SIDEBAR_WIDTH - 3)])
          end
        end
      end

      def render_main_area
        return unless @current_note

        height = lines - 2
        width = cols - SIDEBAR_WIDTH - 2
        start_x = SIDEBAR_WIDTH + 1

        if @mode == :edit
          render_editor(start_x, width, height)
        else
          render_viewer(start_x, width, height)
        end
      end

      def render_viewer(start_x, width, height)
        # Header
        stdscr.setpos(0, start_x)
        stdscr.attron(color_pair(1) | A_BOLD) do
          stdscr.addstr(" #{@current_note[:name]} "[0...width])
        end

        # Render markdown content
        content = @notes_manager.read_note(@current_note[:path])
        rendered = Renderers::MarkdownProcessor.render(content)
        
        lines_array = rendered.split("\n")
        visible_lines = lines_array[@scroll_offset, height - 1] || []
        
        visible_lines.each_with_index do |line, idx|
          stdscr.setpos(idx + 1, start_x)
          # Strip ANSI codes for curses (simple version)
          clean_line = line.gsub(/\e\[[0-9;]*m/, '')[0...width]
          stdscr.addstr(clean_line)
        end

        # Scroll indicator
        if lines_array.length > height - 1
          stdscr.setpos(height - 1, cols - 10)
          stdscr.attron(color_pair(1)) do
            progress = (@scroll_offset * 100 / [lines_array.length - height + 1, 1].max)
            stdscr.addstr(" [#{progress}%] ")
          end
        end
      end

      def render_editor(start_x, width, height)
        # Header
        stdscr.setpos(0, start_x)
        stdscr.attron(color_pair(6) | A_BOLD) do
          stdscr.addstr(" EDITING: #{@current_note[:name]} "[0...width])
        end

        # Show editable content
        visible_lines = @edit_buffer[@scroll_offset, height - 1] || []
        
        visible_lines.each_with_index do |line, idx|
          stdscr.setpos(idx + 1, start_x)
          actual_line = @scroll_offset + idx
          
          if actual_line == @edit_cursor_line
            stdscr.attron(color_pair(4)) do
              stdscr.addstr("> #{line}"[0...width])
            end
          else
            stdscr.addstr("  #{line}"[0...width])
          end
        end

        # Cursor position indicator
        stdscr.setpos(height - 1, cols - 20)
        stdscr.attron(color_pair(6)) do
          stdscr.addstr(" L:#{@edit_cursor_line + 1}/#{@edit_buffer.length} ")
        end
      end

      def render_status_bar
        status_line = lines - 2
        
        stdscr.setpos(status_line, 0)
        stdscr.attron(color_pair(1)) do
          stdscr.addstr('─' * cols)
        end

        stdscr.setpos(lines - 1, 0)
        stdscr.attron(color_pair(1)) do
          mode_str = case @mode
                     when :edit then '[EDIT]'
                     when :command then '[COMMAND]'
                     else '[VIEW]'
                     end
          
          status = " #{mode_str} "
          status += " Notes: #{get_current_notes.length} "
          status += " Folder: #{@current_folder} "
          
          stdscr.addstr(status.ljust(cols))
        end

        # Help hint
        stdscr.setpos(lines - 1, cols - 25)
        stdscr.attron(color_pair(3)) do
          stdscr.addstr(' Press ? for help ')
        end
      end

      def render_help
        help_height = 20
        help_width = 60
        start_y = (lines - help_height) / 2
        start_x = (cols - help_width) / 2

        # Background
        (start_y...start_y + help_height).each do |y|
          stdscr.setpos(y, start_x)
          stdscr.attron(color_pair(5)) do
            stdscr.addstr(' ' * help_width)
          end
        end

        # Border
        stdscr.attron(color_pair(5) | A_BOLD) do
          stdscr.setpos(start_y, start_x)
          stdscr.addstr('┌' + '─' * (help_width - 2) + '┐')
          
          (start_y + 1...start_y + help_height - 1).each do |y|
            stdscr.setpos(y, start_x)
            stdscr.addstr('│')
            stdscr.setpos(y, start_x + help_width - 1)
            stdscr.addstr('│')
          end
          
          stdscr.setpos(start_y + help_height - 1, start_x)
          stdscr.addstr('└' + '─' * (help_width - 2) + '┘')
        end

        # Help content
        help_text = [
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

        help_text.each_with_index do |line, idx|
          stdscr.setpos(start_y + 1 + idx, start_x + 2)
          stdscr.attron(color_pair(5)) do
            stdscr.addstr(line[0...(help_width - 4)])
          end
        end
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
          search_notes
        when 10, KEY_ENTER, 13 # Enter key
          open_selected_note
        end
      end

      def handle_edit_input(char)
        case char
        when 'q', 27 # ESC
          @mode = :view
          @current_note = nil if @current_note
          @selected_note_index = 0
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
          # Insert line
          @edit_buffer.insert(@edit_cursor_line + 1, '')
          @edit_cursor_line += 1
        when 'x'
          # Delete line
          @edit_buffer.delete_at(@edit_cursor_line) if @edit_buffer.length > 1
        when 'o'
          # Edit current line (simplified - just opens external editor)
          edit_line_externally
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
        folders = @notes_manager.list_folders
        notes_start = [folders.length + 5, 10].max
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
        elsif @edit_cursor_line >= @scroll_offset + height - 1
          @scroll_offset = @edit_cursor_line - height + 2
        end
      end

      def open_selected_note
        notes = get_current_notes
        return if notes.empty?

        @current_note = notes[@selected_note_index]
        @scroll_offset = 0
      end

      def enter_edit_mode
        return unless @current_note

        content = @notes_manager.read_note(@current_note[:path])
        @edit_buffer = content.split("\n")
        @edit_cursor_line = 0
        @scroll_offset = 0
        @mode = :edit
      end

      def save_note
        return unless @current_note

        content = @edit_buffer.join("\n")
        @notes_manager.write_note(@current_note[:path], content)
      end

      def create_new_note
        # Simplified: create with timestamp
        timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
        name = "note_#{timestamp}"
        path = @notes_manager.create_note(name)
        
        # Reload and select new note
        @selected_note_index = 0
        @current_note = nil
      end

      def delete_current_note
        return unless @current_note

        @notes_manager.delete_note(@current_note[:path])
        @current_note = nil
        @selected_note_index = 0
      end

      def search_notes
        # Simplified search - this would be more interactive with tty-prompt
        # For now, just reset view
        @scroll_offset = 0
      end

      def edit_line_externally
        # Simplified - in a real app, this would open $EDITOR
        # For now, just a placeholder
      end

      def get_current_notes
        if @current_folder == 'All Notes'
          @notes_manager.list_notes
        else
          @notes_manager.list_notes(@current_folder)
        end
      end
    end
  end
end
