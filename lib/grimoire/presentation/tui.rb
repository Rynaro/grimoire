# frozen_string_literal: true

require "curses"
require "shellwords"
require "set"

module Grimoire
  module Presentation
    # Primary Curses interface for navigating, editing, and searching notes
    class TUI
      SidebarEntry = Struct.new(:type, :label, :path, :depth, :note, keyword_init: true)

      attr_reader :catalog, :config, :search_service

      def initialize(catalog:, search_service:, config:)
        @catalog = catalog
        @search_service = search_service
        @config = config
        @sidebar_entries = []
        @sidebar_scroll = 0
        @selected_index = 0
        @collapsed_folders = Set.new
        @focus = :sidebar
        @status_message = "Welcome to Grimoire"
        @status_style = :info
        @note_lines = []
        @note_scroll = 0
        @note_cursor_line = 0
        @note_links_by_line = {}
        @active_note = nil
        @running = false
        @help_text = "Tab switch • n new note • f new folder • d delete • e edit • / find • ? grep • o open link • q quit"
        @overlay_window = nil
    end

    def start
      setup_curses
      reload_sidebar(preserve_note: false)
      open_first_note
      @running = true
      while @running
        render
        key = Curses.getch
        handle_input(key)
      end
    ensure
      teardown_curses
    end

    private

    def setup_curses
      Curses.init_screen
      Curses.curs_set(0)
      Curses.noecho
      Curses.stdscr.keypad(true)
      Curses.timeout = -1
      init_colors
    end

    def teardown_curses
      Curses.close_screen
    rescue StandardError
      # ignore
    end

    def init_colors
      return unless Curses.has_colors?

      Curses.start_color
      Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)  # default text
      Curses.init_pair(2, Curses::COLOR_BLACK, Curses::COLOR_CYAN)   # sidebar selection
      Curses.init_pair(3, Curses::COLOR_YELLOW, Curses::COLOR_BLACK) # headings
      Curses.init_pair(4, Curses::COLOR_RED, Curses::COLOR_BLACK)    # errors
      Curses.init_pair(5, Curses::COLOR_GREEN, Curses::COLOR_BLACK)  # success
      Curses.init_pair(6, Curses::COLOR_CYAN, Curses::COLOR_BLACK)   # accents
      Curses.init_pair(7, Curses::COLOR_BLACK, Curses::COLOR_YELLOW) # status highlight
      Curses.init_pair(8, Curses::COLOR_BLUE, Curses::COLOR_BLACK)   # secondary
      Curses.init_pair(9, Curses::COLOR_WHITE, Curses::COLOR_BLUE)   # note cursor
    end

    def color_pair(symbol)
      return Curses.color_pair(1) unless Curses.has_colors?

      case symbol
      when :default then Curses.color_pair(1)
      when :sidebar_selected then Curses.color_pair(2) | Curses::A_BOLD
      when :heading then Curses.color_pair(3) | Curses::A_BOLD
      when :error then Curses.color_pair(4) | Curses::A_BOLD
      when :success then Curses.color_pair(5) | Curses::A_BOLD
      when :accent then Curses.color_pair(6)
      when :status then Curses.color_pair(7) | Curses::A_BOLD
      when :quote then Curses.color_pair(8)
      when :cursor then Curses.color_pair(9) | Curses::A_BOLD
      else
        Curses.color_pair(1)
      end
    end

    def render
      refresh_dimensions
      Curses.clear
      if @screen_width < 80 || @screen_height < 18
        Curses.setpos(0, 0)
        Curses.attrset(color_pair(:error))
        Curses.addstr("Please enlarge the terminal (min 80x18).")
        Curses.refresh
        return
      end

      draw_sidebar
      draw_note_area
      draw_status
      Curses.refresh
    end

    def refresh_dimensions
      @screen_height = Curses.lines
      @screen_width = Curses.cols
      max_sidebar = (@screen_width * 0.4).floor
      @sidebar_width = [[30, max_sidebar].min, 22].max
    end

    def draw_sidebar
      height = @screen_height - 2
      width = @sidebar_width
      height.times do |row|
        entry_index = @sidebar_scroll + row
        entry = @sidebar_entries[entry_index]
        y = row
        Curses.setpos(y, 0)
        Curses.attrset(color_pair(:default))
        Curses.addstr(" " * width)
        next unless entry

        line = sidebar_line(entry)
        attr = color_pair(:default)
        if entry_index == @selected_index && @focus == :sidebar
          attr = color_pair(:sidebar_selected)
        elsif entry.type == :folder
          attr = color_pair(:accent) | Curses::A_BOLD
        end

        Curses.setpos(y, 0)
        Curses.attrset(attr)
        Curses.addstr(line.ljust(width)[0...width])
      end

      draw_vertical_divider
    end

    def draw_vertical_divider
      divider_x = @sidebar_width
      (@screen_height - 2).times do |row|
        Curses.setpos(row, divider_x)
        Curses.attrset(color_pair(:default))
        Curses.addch("|")
      end
    end

    def sidebar_line(entry)
      indent = "  " * entry.depth
      case entry.type
      when :folder
        marker = collapsed?(entry.path) ? "▸" : "▾"
        "#{indent}#{marker} #{entry.label}"
      else
        "#{indent}• #{entry.label}"
      end
    end

    def draw_note_area
      note_x = @sidebar_width + 1
      note_width = @screen_width - note_x
      note_height = @screen_height - 2
      return draw_empty_note(note_x, note_width, note_height) unless @active_note

      draw_note_header(note_x, note_width)
      body_height = note_height - 1
      visible_lines = @note_lines[@note_scroll, body_height] || []
      inside_code = false
      visible_lines.each_with_index do |line, idx|
        global_index = @note_scroll + idx
        y = idx + 1
        Curses.setpos(y, note_x)
        Curses.attrset(color_pair(:default))
        Curses.addstr(" " * note_width)
        Curses.setpos(y, note_x)

        highlight = @focus == :note && global_index == @note_cursor_line
        tokens = Formatter.highlight(line, inside_code:)
        draw_tokens(tokens, note_width, highlight)

        fence = line.strip
        inside_code = !inside_code if fence.start_with?("```")
      end
    end

    def draw_empty_note(note_x, note_width, note_height)
      note_height.times do |row|
        Curses.setpos(row, note_x)
        Curses.attrset(color_pair(:default))
        Curses.addstr(" " * note_width)
      end
      Curses.setpos(1, note_x + 2)
      Curses.attrset(color_pair(:accent))
      Curses.addstr("No note selected. Press 'n' to create one.")
    end

    def draw_note_header(note_x, note_width)
      title = @active_note.title
      subtitle = catalog.relative_path(@active_note.path)
      header = "#{title} — #{subtitle}"
      Curses.setpos(0, note_x)
      Curses.attrset(color_pair(:heading))
      Curses.addstr(header.ljust(note_width)[0...note_width])
    end

    def draw_tokens(tokens, note_width, highlight)
      col = 0
      tokens.each do |token|
        break if col >= note_width

        text = token.text
        next if text.nil? || text.empty?

        remaining = note_width - col
        snippet = text[0...remaining]
        attr = token_attribute(token, highlight)
        Curses.attrset(attr)
        Curses.addstr(snippet)
        col += snippet.length
      end
    end

    def token_attribute(token, highlight)
      return color_pair(:cursor) if highlight

      case token.type
      when :heading_prefix, :heading_text then color_pair(:heading)
      when :link then color_pair(:success)
      when :strong then color_pair(:accent) | Curses::A_BOLD
      when :quote then color_pair(:quote)
      when :checkbox, :list_marker then color_pair(:accent)
      when :code, :code_fence then color_pair(:quote)
      else
        color_pair(:default)
      end
    end

    def draw_status
      status_y = @screen_height - 2
      help_y = @screen_height - 1

      Curses.setpos(status_y, 0)
      Curses.attrset(status_style_attribute)
      Curses.addstr(@status_message.ljust(@screen_width)[0...@screen_width])

      Curses.setpos(help_y, 0)
      Curses.attrset(color_pair(:default))
      Curses.addstr(@help_text.ljust(@screen_width)[0...@screen_width])
    end

    def status_style_attribute
      case @status_style
      when :error then color_pair(:error)
      when :success then color_pair(:success)
      else
        color_pair(:default)
      end
    end

    def handle_input(key)
      case key
      when nil
        return
      when Curses::KEY_RESIZE
        return
      when "\t".ord
        toggle_focus
        return
      when ?q.ord
        @running = false
        return
      when ?n.ord
        create_note_flow
      when ?f.ord
        create_folder_flow
      when ?d.ord
        delete_current
      when ?e.ord
        edit_current_note
      when ?/.ord
        search_titles_flow
      when '?'.ord
        search_content_flow
      when ?o.ord
        open_link_from_cursor
      else
        @focus == :sidebar ? handle_sidebar_input(key) : handle_note_input(key)
      end
    end

    def toggle_focus
      @focus = @focus == :sidebar ? :note : :sidebar
      message("Focus switched to #{@focus}")
    end

    def handle_sidebar_input(key)
      case key
      when Curses::KEY_UP then move_selection(-1)
      when Curses::KEY_DOWN then move_selection(1)
      when Curses::KEY_NPAGE then move_selection(view_height)
      when Curses::KEY_PPAGE then move_selection(-view_height)
      when Curses::KEY_HOME then move_selection(-@sidebar_entries.length)
      when Curses::KEY_END then move_selection(@sidebar_entries.length)
      when Curses::KEY_RIGHT, 10, 13
        open_selected_entry
      when Curses::KEY_LEFT
        collapse_selected_folder
      when " ".ord
        toggle_folder(current_entry&.path)
      else
        return false
      end
      true
    end

    def handle_note_input(key)
      case key
      when Curses::KEY_UP then move_note_cursor(-1)
      when Curses::KEY_DOWN then move_note_cursor(1)
      when Curses::KEY_PPAGE then move_note_cursor(-view_height)
      when Curses::KEY_NPAGE then move_note_cursor(view_height)
      when Curses::KEY_HOME then move_note_cursor(-@note_lines.length)
      when Curses::KEY_END then move_note_cursor(@note_lines.length)
      when 10, 13 then open_link_from_cursor
      else
        return false
      end
      true
    end

    def move_selection(delta)
      return if @sidebar_entries.empty?

      @selected_index = (@selected_index + delta).clamp(0, @sidebar_entries.length - 1)
      adjust_sidebar_scroll
      entry = current_entry
      load_note(entry.note) if entry&.type == :note && @focus == :note
    end

    def adjust_sidebar_scroll
      height = view_height
      if @selected_index < @sidebar_scroll
        @sidebar_scroll = @selected_index
      elsif @selected_index >= (@sidebar_scroll + height)
        @sidebar_scroll = @selected_index - height + 1
      end
    end

    def move_note_cursor(delta)
      return unless @active_note

      @note_cursor_line = (@note_cursor_line + delta).clamp(0, [@note_lines.length - 1, 0].max)
      height = view_height - 1
      if @note_cursor_line < @note_scroll
        @note_scroll = @note_cursor_line
      elsif @note_cursor_line >= (@note_scroll + height)
        @note_scroll = @note_cursor_line - height + 1
      end
    end

    def open_selected_entry
      entry = current_entry
      return unless entry

      if entry.type == :folder
        toggle_folder(entry.path)
      else
        load_note(entry.note)
        @focus = :note
      end
    end

    def collapse_selected_folder
      entry = current_entry
      return unless entry&.type == :folder

      @collapsed_folders << entry.path
      reload_sidebar
    end

    def toggle_folder(path)
      return unless path

      if collapsed?(path)
        @collapsed_folders.delete(path)
      else
        @collapsed_folders << path
      end
      reload_sidebar
    end

    def collapsed?(path)
      @collapsed_folders.include?(path.to_s)
    end

    def current_entry
      @sidebar_entries[@selected_index]
    end

    def current_folder_path
      entry = current_entry
      case entry&.type
      when :folder
        normalize_folder(entry.path)
      when :note
        normalize_folder(entry.note.folder)
      else
        ""
      end
    end

    def normalize_folder(path)
      path = path.to_s
      (path.empty? || path == ".") ? "" : path
    end

    def load_note(note)
      @active_note = note
      @note_lines = note.lines
      @note_scroll = 0
      @note_cursor_line = 0
      @note_links_by_line = {}
      @note_lines.each_with_index do |line, idx|
        matches = line.scan(Domain::Note::LINK_PATTERN).flatten
        @note_links_by_line[idx] = matches if matches.any?
      end
      message("Opened #{note.id}")
    rescue Errno::ENOENT
      message("Note missing on disk", style: :error)
      reload_sidebar(preserve_note: false)
    end

    def open_first_note
      entry_index = @sidebar_entries.index { |entry| entry.type == :note }
      if entry_index
        @selected_index = entry_index
        load_note(@sidebar_entries[entry_index].note)
      else
        @active_note = nil
        @note_lines = []
      end
    end

    def reload_sidebar(preserve_note: true)
      @sidebar_entries = build_sidebar_entries
      @selected_index = @sidebar_entries.find_index { |e| e.type == :note && @active_note && e.note.id == @active_note.id } if preserve_note && @active_note
      @selected_index ||= @sidebar_entries.find_index { |entry| entry.type == :note } || 0
      @selected_index = 0 if @sidebar_entries.empty?
      adjust_sidebar_scroll
    end

    def build_sidebar_entries
      entries = []
      build_folder_entries("", 0, entries)
      entries
    end

    def build_folder_entries(folder_rel, depth, entries)
      label = folder_rel.empty? ? catalog.root_label : File.basename(folder_rel)
      entries << SidebarEntry.new(type: :folder, label:, path: folder_rel, depth:, note: nil)

      return entries if collapsed?(folder_rel)

      catalog.notes_in(folder_rel).each do |note|
        entries << SidebarEntry.new(
          type: :note,
          label: note.title,
          path: note.id,
          depth: depth + 1,
          note:
        )
      end

      catalog.subfolders(folder_rel).each do |child_rel|
        build_folder_entries(child_rel, depth + 1, entries)
      end
    end

    def create_note_flow
      title = prompt("Note title (use Folder/Title for nested):")
      return unless title

      folder = current_folder_path
      if title.include?("/")
        parts = title.split("/")
        title = parts.pop
        folder = File.join(folder, *parts)
      end

      note = catalog.create_note(folder:, title:)
      reload_sidebar(preserve_note: false)
      if (idx = @sidebar_entries.index { |entry| entry.type == :note && entry.note.id == note.id })
        @selected_index = idx
        load_note(note)
      end
      message("Note created at #{note.id}", style: :success)
    rescue Error => e
      message(e.message, style: :error)
    end

    def create_folder_flow
      folder = prompt("Folder path relative to root:")
      return unless folder

      catalog.create_folder(folder)
      reload_sidebar
      message("Folder created", style: :success)
    rescue Error => e
      message(e.message, style: :error)
    end

    def delete_current
      entry = current_entry
      return unless entry

      case entry.type
      when :note
        return unless confirm?("Delete note #{entry.note.title}?")

        catalog.delete_note(entry.note.id)
        reload_sidebar(preserve_note: false)
        open_first_note
        message("Note deleted", style: :success)
      when :folder
        if entry.path.empty?
          message("Cannot delete root folder", style: :error)
          return
        end

        return unless confirm?("Delete folder #{entry.path} (and contents)?")

        catalog.delete_folder(entry.path)
        reload_sidebar(preserve_note: false)
        open_first_note
        message("Folder deleted", style: :success)
      end
    rescue Error => e
      message(e.message, style: :error)
    end

    def edit_current_note
      note = @active_note
      return unless note

      begin
        Curses.def_prog_mode
        Curses.close_screen
        command = Shellwords.split(config.editor)
        command << note.path.to_s
        system(*command)
      ensure
        Curses.reset_prog_mode
        Curses.refresh
      end
      load_note(note)
      reload_sidebar
    rescue StandardError => e
      message("Editor error: #{e.message}", style: :error)
    end

    def search_titles_flow
      query = prompt("Search titles:")
      return unless query

      results = search_service.by_title(query)
      if results.empty?
        message("No matches for '#{query}'", style: :error)
        return
      end

      choice = choose_from_list(results, title: "Matches for '#{query}'") { |note| note.id }
      return unless choice

      load_note(choice)
      reload_sidebar
      select_note(choice)
    end

    def search_content_flow
      query = prompt("Search content:")
      return unless query

      results = search_service.by_content(query)
      if results.empty?
        message("No matches for '#{query}'", style: :error)
        return
      end

      choice = choose_from_list(results, title: "Content matches") do |result|
        "#{result.note.id}:#{result.line_number} #{result.line.strip}"
      end
      return unless choice

      load_note(choice.note)
      reload_sidebar
      select_note(choice.note)
      @note_cursor_line = choice.line_number - 1
      @note_scroll = [@note_cursor_line - (view_height / 2), 0].max
    end

    def select_note(note)
      idx = @sidebar_entries.index { |entry| entry.type == :note && entry.note.id == note.id }
      return unless idx

      @selected_index = idx
      adjust_sidebar_scroll
    end

    def open_link_from_cursor
      return unless @active_note

      links = @note_links_by_line[@note_cursor_line]
      unless links&.any?
        message("No links on this line")
        return
      end

      target_name = if links.length == 1
                      links.first
                    else
                      choose_from_list(links, title: "Select link") { |link| link }
                    end
      return unless target_name

      note = catalog.resolve_link(target_name, current_folder: @active_note.folder)
      if note&.exists?
        load_note(note)
        reload_sidebar
        select_note(note)
      else
        message("Link not found: #{target_name}", style: :error)
      end
    end

    def choose_from_list(items, title:)
      return nil if items.empty?

      selected = 0
      offset = 0
      capacity = overlay_capacity(items.length)
      loop do
        draw_overlay(title, items, selected, offset) { |item| yield(item) }
        key = Curses.getch
        case key
        when Curses::KEY_UP
          selected = [selected - 1, 0].max
        when Curses::KEY_DOWN
          selected = [selected + 1, items.length - 1].min
        when Curses::KEY_NPAGE
          selected = [selected + 5, items.length - 1].min
        when Curses::KEY_PPAGE
          selected = [selected - 5, 0].max
        when 10, 13
          clear_overlay
          return items[selected]
        when 27, ?q.ord
          clear_overlay
          return nil
        end
        offset = [[selected - capacity + 1, 0].max, selected].min
      end
    ensure
      clear_overlay
    end

    def draw_overlay(title, items, selected, offset)
      width = [title.length + 4, items.map { |item| yield(item).length }.max + 4, 40].compact.max
      height = overlay_height(items.length)
      top = ((@screen_height - height) / 2).clamp(0, @screen_height - height)
      left = ((@screen_width - width) / 2).clamp(0, @screen_width - width)

      @overlay_window&.close
      @overlay_window = Curses::Window.new(height, width, top, left)
      @overlay_window.box("|", "-")
      @overlay_window.attrset(color_pair(:heading))
      @overlay_window.setpos(0, 2)
      @overlay_window.addstr(" #{title} ")

      list_height = height - 2
      visible_items = items[offset, list_height] || []
      visible_items.each_with_index do |item, idx|
        label = yield(item)
        row = idx + 1
        actual_index = offset + idx
        attr = actual_index == selected ? color_pair(:sidebar_selected) : color_pair(:default)
        @overlay_window.attrset(attr)
        @overlay_window.setpos(row, 2)
        @overlay_window.addstr(label.ljust(width - 4)[0...(width - 4)])
      end
      @overlay_window.refresh
    end

    def overlay_height(count)
      [[count + 4, @screen_height - 2].min, 8].max
    end

    def overlay_capacity(count)
      overlay_height(count) - 2
    end

    def clear_overlay
      @overlay_window&.close
      @overlay_window = nil
    rescue StandardError
      @overlay_window = nil
    end

    def prompt(message)
      draw_status_prompt(message)
      Curses.echo
      Curses.curs_set(1)
      input = Curses.getstr
      input = input&.strip
      input = nil if input.nil? || input.empty?
      input
    ensure
      Curses.noecho
      Curses.curs_set(0)
      message("Ready")
    end

    def confirm?(question)
      answer = prompt("#{question} (y/N)")
      answer&.downcase == "y"
    end

    def draw_status_prompt(message)
      status_y = @screen_height - 2
      Curses.setpos(status_y, 0)
      Curses.attrset(color_pair(:status))
      Curses.addstr(message.ljust(@screen_width)[0...@screen_width])
      Curses.setpos(status_y, message.length + 1)
    end

    def message(text, style: :info)
      @status_message = text
      @status_style = style
    end

    def view_height
      @screen_height - 2
    end
  end
end
end
