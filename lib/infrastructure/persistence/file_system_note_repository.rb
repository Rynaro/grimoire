# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require_relative '../../domain/repositories/note_repository'
require_relative '../../domain/entities/note'
require_relative '../../domain/value_objects/note_path'
require_relative '../../domain/value_objects/note_content'
require_relative '../../domain/value_objects/note_metadata'
require_relative '../../domain/value_objects/folder_path'

module Grimoire
  module Infrastructure
    module Persistence
      # FileSystemNoteRepository - Infrastructure Implementation
      # Implements the NoteRepository interface using the file system
      # Follows Dependency Inversion Principle
      class FileSystemNoteRepository < Domain::Repositories::NoteRepository
        attr_reader :root_dir

        def initialize(root_dir = nil)
          @root_dir = Pathname.new(root_dir || default_notes_dir)
          ensure_directory_exists
        end

        def save(note)
          full_path = @root_dir.join(note.path.to_s)
          FileUtils.mkdir_p(full_path.dirname)
          
          File.write(full_path, note.content.to_s)
          
          # Update file system timestamp
          File.utime(note.metadata.modified_at, note.metadata.modified_at, full_path)
        end

        def find_by_path(path)
          path_vo = ensure_note_path(path)
          full_path = @root_dir.join(path_vo.to_s)
          
          return nil unless full_path.exist? && full_path.file?

          build_note_from_file(path_vo, full_path)
        end

        def find_all(folder: nil)
          search_path = if folder.nil? || folder.all_notes?
                         @root_dir
                       else
                         @root_dir.join(folder.to_s)
                       end

          return [] unless search_path.exist?

          Dir.glob(search_path.join('**/*.md')).map do |file_path|
            relative_path = Pathname.new(file_path).relative_path_from(@root_dir).to_s
            note_path = Domain::ValueObjects::NotePath.new(relative_path)
            build_note_from_file(note_path, file_path)
          end.compact.sort_by { |note| note.metadata.modified_at }.reverse
        end

        def exists?(path)
          path_vo = ensure_note_path(path)
          @root_dir.join(path_vo.to_s).exist?
        end

        def delete(path)
          path_vo = ensure_note_path(path)
          full_path = @root_dir.join(path_vo.to_s)
          
          File.delete(full_path) if full_path.exist?
          
          # Clean up empty directories
          cleanup_empty_directories(full_path.dirname)
        end

        def list_folders
          dirs = Dir.glob(@root_dir.join('**/'))
                    .map { |d| Pathname.new(d).relative_path_from(@root_dir).to_s }
                    .reject { |d| d.empty? }
                    .map { |d| Domain::ValueObjects::FolderPath.new(d.chomp('/')) }
                    .sort_by(&:to_s)

          [Domain::ValueObjects::FolderPath.all_notes] + dirs
        end

        private

        def default_notes_dir
          ENV['GRIMOIRE_NOTES_DIR'] || File.join(Dir.home, 'grimoire_notes')
        end

        def ensure_directory_exists
          FileUtils.mkdir_p(@root_dir) unless @root_dir.exist?
        end

        def ensure_note_path(path)
          return path if path.is_a?(Domain::ValueObjects::NotePath)
          Domain::ValueObjects::NotePath.new(path)
        end

        def build_note_from_file(note_path, file_path)
          content = File.read(file_path)
          name = note_path.basename
          modified_at = File.mtime(file_path)
          created_at = File.birthtime(file_path) rescue modified_at

          metadata = Domain::ValueObjects::NoteMetadata.new(
            name: name,
            modified_at: modified_at,
            created_at: created_at
          )

          content_vo = Domain::ValueObjects::NoteContent.new(content)

          Domain::Entities::Note.new(
            path: note_path,
            content: content_vo,
            metadata: metadata
          )
        rescue => e
          warn "Error loading note #{note_path}: #{e.message}"
          nil
        end

        def cleanup_empty_directories(dir)
          return if dir == @root_dir
          return unless dir.exist? && dir.directory?
          return unless dir.children.empty?

          dir.rmdir
          cleanup_empty_directories(dir.parent)
        end
      end
    end
  end
end
