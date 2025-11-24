# frozen_string_literal: true

require_relative '../../domain/repositories/note_repository'
require_relative '../../domain/entities/note'
require_relative '../../domain/value_objects/note_path'
require_relative '../../domain/value_objects/note_name'
require_relative '../../domain/value_objects/note_content'
require 'fileutils'

module Grimoire
  module Infrastructure
    module Repositories
      class FileSystemNoteRepository < Domain::Repositories::NoteRepository
        def initialize(base_directory)
          @base_directory = base_directory
          ensure_directory_exists
        end

        def find_by_path(path)
          path_obj = path.is_a?(Domain::ValueObjects::NotePath) ? path : Domain::ValueObjects::NotePath.new(path)
          full_path = path_obj.full_path(@base_directory)

          return nil unless File.exist?(full_path)

          build_note_from_file(full_path, path_obj)
        end

        def find_all
          notes = []
          Dir.glob(File.join(@base_directory, '**', '*.md')).each do |file_path|
            relative_path = file_path.sub(/^#{Regexp.escape(@base_directory)}\/?/, '')
            path_obj = Domain::ValueObjects::NotePath.new(relative_path)
            notes << build_note_from_file(file_path, path_obj)
          end
          notes.sort_by(&:modified_at).reverse
        end

        def find_by_folder(folder_name)
          folder_path = File.join(@base_directory, folder_name.to_s)
          return [] unless Dir.exist?(folder_path)

          notes = []
          Dir.glob(File.join(folder_path, '*.md')).each do |file_path|
            relative_path = file_path.sub("#{@base_directory}/", '')
            path_obj = Domain::ValueObjects::NotePath.new(relative_path)
            notes << build_note_from_file(file_path, path_obj)
          end
          notes.sort_by(&:modified_at).reverse
        end

        def save(note)
          full_path = note.path.full_path(@base_directory)
          folder_path = File.dirname(full_path)
          FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)

          File.write(full_path, note.content.to_s)
          note
        end

        def delete(path)
          path_obj = path.is_a?(Domain::ValueObjects::NotePath) ? path : Domain::ValueObjects::NotePath.new(path)
          full_path = path_obj.full_path(@base_directory)
          File.delete(full_path) if File.exist?(full_path)
        end

        def exists?(path)
          path_obj = path.is_a?(Domain::ValueObjects::NotePath) ? path : Domain::ValueObjects::NotePath.new(path)
          full_path = path_obj.full_path(@base_directory)
          File.exist?(full_path)
        end

        def search_content(query)
          results = []
          query_lower = query.downcase

          Dir.glob(File.join(@base_directory, '**', '*.md')).each do |file_path|
            content = File.read(file_path)
            next unless content.downcase.include?(query_lower)

            lines = content.lines.each_with_index.select do |line, _|
              line.downcase.include?(query_lower)
            end.map { |line, idx| { line: line.chomp, number: idx + 1 } }

            relative_path = file_path.sub(/^#{Regexp.escape(@base_directory)}\/?/, '')
            path_obj = Domain::ValueObjects::NotePath.new(relative_path)
            note = build_note_from_file(file_path, path_obj)

            results << {
              note: note,
              matches: lines
            }
          end

          results
        end

        private

        def build_note_from_file(file_path, path_obj)
          content = File.read(file_path)
          name = Domain::ValueObjects::NoteName.new(path_obj.name)
          content_obj = Domain::ValueObjects::NoteContent.new(content)
          modified_at = File.mtime(file_path)

          Domain::Entities::Note.new(
            path: path_obj,
            name: name,
            content: content_obj,
            modified_at: modified_at
          )
        end

        def ensure_directory_exists
          FileUtils.mkdir_p(@base_directory) unless Dir.exist?(@base_directory)
        end
      end
    end
  end
end
