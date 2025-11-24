# frozen_string_literal: true

require_relative '../../domain/entities/folder'
require_relative '../../domain/value_objects/folder_name'
require_relative '../../domain/repositories/folder_repository'

module Grimoire
  module Application
    module Services
      # Application service for creating folders
      class CreateFolderService
        def initialize(folder_repository)
          @folder_repository = folder_repository
        end

        def execute(name:)
          folder_name = Domain::ValueObjects::FolderName.new(name)

          if @folder_repository.exists?(folder_name)
            raise ArgumentError, "Folder '#{name}' already exists"
          end

          folder = Domain::Entities::Folder.new(name: folder_name)
          @folder_repository.save(folder)
          folder
        end
      end
    end
  end
end
