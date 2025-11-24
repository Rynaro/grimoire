# frozen_string_literal: true

require_relative '../../domain/services/note_search_service'

module Grimoire
  module Application
    module UseCases
      # SearchNotes Use Case
      # Single Responsibility: Orchestrating note search operations
      class SearchNotes
        def initialize(repository)
          @search_service = Domain::Services::NoteSearchService.new(repository)
        end

        # Search by note name
        # @param query [String]
        # @param folder [String, nil]
        # @return [Array<Domain::Entities::Note>]
        def by_name(query:, folder: nil)
          folder_path = folder ? ensure_folder_path(folder) : nil
          @search_service.search_by_name(query, folder: folder_path)
        end

        # Search by note content
        # @param query [String]
        # @param folder [String, nil]
        # @return [Array<Hash>]
        def by_content(query:, folder: nil)
          folder_path = folder ? ensure_folder_path(folder) : nil
          @search_service.search_by_content(query, folder: folder_path)
        end

        # Find backlinks to a note
        # @param note [Domain::Entities::Note]
        # @return [Array<Domain::Entities::Note>]
        def backlinks(note:)
          @search_service.find_backlinks(note)
        end

        # Find forward links from a note
        # @param note [Domain::Entities::Note]
        # @return [Array<Domain::Entities::Note>]
        def forward_links(note:)
          @search_service.find_forward_links(note)
        end

        private

        def ensure_folder_path(folder)
          return folder if folder.is_a?(Domain::ValueObjects::FolderPath)
          Domain::ValueObjects::FolderPath.new(folder)
        end
      end
    end
  end
end
