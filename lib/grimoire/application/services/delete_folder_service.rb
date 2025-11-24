# frozen_string_literal: true

require_relative '../../domain/value_objects/folder_name'
require_relative '../../domain/repositories/folder_repository'

module Grimoire
  module Application
    module Services
      # Application service for deleting folders
      class DeleteFolderService
        def initialize(folder_repository)
          @folder_repository = folder_repository
        end

        def execute(name:)
          folder_name = name.is_a?(Domain::ValueObjects::FolderName) ? name : Domain::ValueObjects::FolderName.new(name)
          
          unless @folder_repository.exists?(folder_name)
            raise ArgumentError, "Folder does not exist: #{name}"
          end

          @folder_repository.delete(folder_name)
        end
      end
    end
  end
end
