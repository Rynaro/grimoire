# frozen_string_literal: true

require "fileutils"
require "pathname"
require "set"

module Grimoire
  # Manages CRUD operations for folders and notes
  class Repository
    NOTE_EXT = ".md"

    attr_reader :root

    def initialize(root)
      @root = Pathname(root).expand_path
      FileUtils.mkdir_p(@root)
    end

    def list_notes
      Dir.glob(root.join("**/*#{NOTE_EXT}")).sort.map { |path| Note.new(path, root:) }
    end

    def folders
      result = []
      traverse_folders(root, Pathname(".")) { |rel| result << rel }
      result
    end

    def subfolders(relative_folder = ".")
      folder_path = resolve_folder(relative_folder)
      Dir.children(folder_path)
        .reject { |child| child.start_with?(".") }
        .map { |child| folder_path.join(child) }
        .select(&:directory?)
        .sort
        .map { |path| relative_path(path) }
    end

    def notes_in(relative_folder = ".")
      folder_path = resolve_folder(relative_folder)
      Dir.children(folder_path)
        .reject { |child| child.start_with?(".") }
        .map { |child| folder_path.join(child) }
        .select { |path| path.file? && path.extname == NOTE_EXT }
        .sort
        .map { |path| Note.new(path, root:) }
    end

    def find_note(relative_path)
      cleaned = sanitize(relative_path)
      path = root.join(cleaned).expand_path
      ensure_within_root!(path)
      raise NoteNotFoundError, relative_path unless path.exist?

      Note.new(path, root:)
    end

    def create_note(relative_path, content = nil, title: nil)
      cleaned = append_extension(sanitize(relative_path))
      note = Note.new(root.join(cleaned), root:)
      raise UnsafeOperationError, "Note already exists: #{note.id}" if note.exists?

      note.write(content || default_content(title || note.title))
      note
    end

    def create_note_in(folder:, title:)
      folder_rel = sanitize(folder)
      slug = slugify(title)
      relative = File.join(folder_rel, "#{slug}#{NOTE_EXT}")
      create_note(relative, nil, title:)
    end

    def delete_note(relative_path)
      note = find_note(relative_path)
      note.delete
      cleanup_empty_parents(note.path.dirname)
    end

    def create_folder(relative_path)
      folder = resolve_folder(relative_path, create: true)
      folder
    end

    def delete_folder(relative_path)
      folder = resolve_folder(relative_path)
      raise UnsafeOperationError, "Refusing to delete root" if folder == root

      FileUtils.remove_dir(folder, true)
    end

    def resolve_link(reference, current_folder: ".")
      normalized = sanitize(reference)
      normalized = append_extension(normalized) unless normalized.end_with?(NOTE_EXT)
      folder_rel = sanitize(current_folder)
      local_candidate = root.join(folder_rel, normalized).cleanpath
      ensure_within_root!(local_candidate)
      return Note.new(local_candidate, root:) if local_candidate.exist?

      slug = slugify(reference)
      matches = Dir.glob(root.join("**/#{slug}#{NOTE_EXT}")).sort
      return nil if matches.empty?
      return Note.new(matches.first, root:) if matches.one?

      nil # ambiguous reference
    end

    def slugify(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    end

    def default_content(title)
      <<~MARKDOWN
        # #{title}

        _Created #{Time.now.strftime("%Y-%m-%d %H:%M")}_

      MARKDOWN
    end

    def relative_path(path)
      path = Pathname(path)
      path.relative_path_from(root).to_s
    end

    private

    def traverse_folders(current_path, relative, &block)
      block.call(relative)
      Dir.children(current_path).sort.each do |child|
        next if child.start_with?(".")

        child_path = current_path.join(child)
        next unless child_path.directory?

        traverse_folders(child_path, relative_path(child_path), &block)
      end
    end

    def sanitize(path)
      raw = path.to_s.strip
      return "" if raw.empty? || raw == "."

      Pathname(raw).each_filename
                   .reject { |segment| segment == ".." }
                   .join("/")
                   .sub(%r{\A/+}, "")
    end

    def append_extension(path)
      path.end_with?(NOTE_EXT) ? path : "#{path}#{NOTE_EXT}"
    end

    def resolve_folder(relative_path, create: false)
      cleaned = sanitize(relative_path)
      target = cleaned.empty? ? root : root.join(cleaned)
      ensure_within_root!(target)
      FileUtils.mkdir_p(target) if create
      target
    end

    def ensure_within_root!(path)
      expanded = Pathname(path).expand_path
      return if expanded.to_s.start_with?(root.to_s)

      raise UnsafeOperationError, "Path escapes root: #{path}"
    end

    def cleanup_empty_parents(start_path)
      path = Pathname(start_path)
      while path != root && path.children.empty?
        path.rmdir
        path = path.parent
      end
    rescue Errno::ENOTEMPTY, Errno::ENOENT
      # ignore
    end
  end
end
