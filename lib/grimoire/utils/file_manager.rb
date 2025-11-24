# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Grimoire
  module Utils
    class FileManager
      attr_reader :notes_dir

      def initialize(notes_dir = nil)
        @notes_dir = notes_dir || File.join(Dir.home, '.grimoire', 'notes')
        ensure_notes_directory
      end

      def ensure_notes_directory
        FileUtils.mkdir_p(@notes_dir) unless Dir.exist?(@notes_dir)
      end

      def list_folders
        Dir.glob(File.join(@notes_dir, '*/')).map do |path|
          File.basename(path)
        end.sort
      end

      def list_notes(folder = nil)
        base_path = folder ? File.join(@notes_dir, folder) : @notes_dir
        return [] unless Dir.exist?(base_path)

        Dir.glob(File.join(base_path, '*.md')).map do |path|
          {
            name: File.basename(path, '.md'),
            path: path,
            folder: folder,
            modified: File.mtime(path)
          }
        end.sort_by { |note| note[:modified] }.reverse
      end

      def list_all_items
        items = []
        
        # Add folders
        list_folders.each do |folder|
          items << { type: :folder, name: folder, path: File.join(@notes_dir, folder) }
        end

        # Add root notes
        list_notes.each do |note|
          items << { type: :note, **note }
        end

        # Add notes in folders
        list_folders.each do |folder|
          list_notes(folder).each do |note|
            items << { type: :note, **note }
          end
        end

        items.sort_by do |item|
          [item[:type] == :folder ? 0 : 1, item[:name]]
        end
      end

      def create_note(name, folder = nil, content = '')
        folder_path = folder ? File.join(@notes_dir, folder) : @notes_dir
        FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)
        
        file_path = File.join(folder_path, "#{name}.md")
        File.write(file_path, content) unless File.exist?(file_path)
        file_path
      end

      def create_folder(name)
        folder_path = File.join(@notes_dir, name)
        FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)
        folder_path
      end

      def delete_note(path)
        File.delete(path) if File.exist?(path)
      end

      def delete_folder(path)
        FileUtils.rm_rf(path) if Dir.exist?(path)
      end

      def read_note(path)
        File.read(path) if File.exist?(path)
      end

      def write_note(path, content)
        File.write(path, content)
      end

      def search_files(query)
        query_lower = query.downcase
        list_all_items.select do |item|
          item[:name].downcase.include?(query_lower)
        end
      end

      def search_content(query)
        results = []
        query_lower = query.downcase

        Dir.glob(File.join(@notes_dir, '**', '*.md')).each do |path|
          content = File.read(path)
          if content.downcase.include?(query_lower)
            lines = content.lines.each_with_index.select do |line, _|
              line.downcase.include?(query_lower)
            end.map { |line, idx| { line: line.chomp, number: idx + 1 } }

            results << {
              path: path,
              name: File.basename(path, '.md'),
              folder: File.dirname(path) == @notes_dir ? nil : File.basename(File.dirname(path)),
              matches: lines
            }
          end
        end

        results
      end

      def find_linked_notes(content)
        # Find markdown links and wiki-style links [[note name]]
        links = []
        
        # Wiki-style links: [[note name]]
        content.scan(/\[\[([^\]]+)\]\]/) do |match|
          links << { type: :wiki, name: match[0], original: "[[#{match[0]}]]" }
        end

        # Markdown links: [text](note.md) or [text](folder/note.md)
        content.scan(/\[([^\]]+)\]\(([^)]+)\)/) do |text, link|
          links << { type: :markdown, name: File.basename(link, '.md'), original: "[#{text}](#{link})" }
        end

        links
      end
    end
  end
end
