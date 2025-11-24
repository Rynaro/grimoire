# frozen_string_literal: true

module Grimoire
  module Application
    module UseCases
      # ListNotes Use Case
      # Single Responsibility: Listing notes with optional filtering
      class ListNotes
        def initialize(repository)
          @repository = repository
        end

        # @param folder [String, Domain::ValueObjects::FolderPath, nil]
        # @return [Array<Domain::Entities::Note>]
        def call(folder: nil)
          folder_path = folder ? ensure_folder_path(folder) : nil
          @repository.find_all(folder: folder_path)
        end

        # @return [Array<Domain::ValueObjects::FolderPath>]
        def folders
          @repository.list_folders
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
