# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Grimoire
  module Core
    # Manages note files and directory structure
    class NotesManager
      attr_reader :root_dir

      def initialize(root_dir = nil)
        @root_dir = Pathname.new(root_dir || default_notes_dir)
        ensure_directory_exists
      end

      def list_notes(folder = nil)
        dir = folder ? @root_dir.join(folder) : @root_dir
        return [] unless dir.exist?

        Dir.glob(dir.join('**/*.md')).map do |path|
          relative_path = Pathname.new(path).relative_path_from(@root_dir).to_s
          {
            name: File.basename(path, '.md'),
            path: relative_path,
            full_path: path,
            modified: File.mtime(path)
          }
        end.sort_by { |n| n[:modified] }.reverse
      end

      def list_folders
        dirs = Dir.glob(@root_dir.join('**/'))
                   .map { |d| Pathname.new(d).relative_path_from(@root_dir).to_s }
                   .reject { |d| d.empty? }
        
        ['All Notes'] + dirs.map { |d| d.chomp('/') }.sort
      end

      def read_note(path)
        full_path = @root_dir.join(path)
        return nil unless full_path.exist?

        File.read(full_path)
      end

      def write_note(path, content)
        full_path = @root_dir.join(path)
        FileUtils.mkdir_p(full_path.dirname)
        File.write(full_path, content)
      end

      def create_note(name, folder = nil)
        filename = "#{sanitize_filename(name)}.md"
        path = folder ? File.join(folder, filename) : filename
        full_path = @root_dir.join(path)

        FileUtils.mkdir_p(full_path.dirname)
        File.write(full_path, "# #{name}\n\n") unless full_path.exist?
        
        path
      end

      def delete_note(path)
        full_path = @root_dir.join(path)
        File.delete(full_path) if full_path.exist?
      end

      def search_notes(query)
        list_notes.select do |note|
          note[:name].downcase.include?(query.downcase)
        end
      end

      def search_content(query)
        results = []
        list_notes.each do |note|
          content = read_note(note[:path])
          next unless content

          content.lines.each_with_index do |line, index|
            if line.downcase.include?(query.downcase)
              results << {
                note: note,
                line_number: index + 1,
                line: line.strip
              }
            end
          end
        end
        results
      end

      def find_linked_notes(content)
        # Find [[note name]] style links
        content.scan(/\[\[([^\]]+)\]\]/).flatten
      end

      private

      def default_notes_dir
        ENV['GRIMOIRE_NOTES_DIR'] || File.join(Dir.home, 'grimoire_notes')
      end

      def ensure_directory_exists
        FileUtils.mkdir_p(@root_dir) unless @root_dir.exist?
      end

      def sanitize_filename(name)
        name.gsub(/[^0-9A-Za-z.\-_]/, '_')
      end
    end
  end
end
