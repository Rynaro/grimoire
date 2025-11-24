# frozen_string_literal: true

require_relative '../../infrastructure/repositories/file_system_note_repository'
require_relative '../../infrastructure/repositories/file_system_folder_repository'
require_relative 'services/create_note_service'
require_relative 'services/delete_note_service'
require_relative 'services/update_note_service'
require_relative 'services/search_notes_service'
require_relative 'services/create_folder_service'
require_relative 'services/delete_folder_service'

module Grimoire
  module Application
    # Service Container - Dependency Injection container
    # Follows Dependency Inversion Principle
    class ServiceContainer
      attr_reader :note_repository, :folder_repository

      def initialize(base_directory = nil)
        base_dir = base_directory || File.join(Dir.home, '.grimoire', 'notes')
        
        @note_repository = Infrastructure::Repositories::FileSystemNoteRepository.new(base_dir)
        @folder_repository = Infrastructure::Repositories::FileSystemFolderRepository.new(base_dir)
        
        @create_note_service = Services::CreateNoteService.new(@note_repository)
        @delete_note_service = Services::DeleteNoteService.new(@note_repository)
        @update_note_service = Services::UpdateNoteService.new(@note_repository)
        @search_notes_service = Services::SearchNotesService.new(@note_repository, @folder_repository)
        @create_folder_service = Services::CreateFolderService.new(@folder_repository)
        @delete_folder_service = Services::DeleteFolderService.new(@folder_repository)
      end

      def create_note_service
        @create_note_service
      end

      def delete_note_service
        @delete_note_service
      end

      def update_note_service
        @update_note_service
      end

      def search_notes_service
        @search_notes_service
      end

      def create_folder_service
        @create_folder_service
      end

      def delete_folder_service
        @delete_folder_service
      end
    end
  end
end
