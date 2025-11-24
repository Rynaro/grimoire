# frozen_string_literal: true

module Grimoire
  module Domain
    module Repositories
      # NoteRepository Interface
      # Defines the contract for note persistence
      # Following Interface Segregation Principle
      class NoteRepository
        # @param note [Entities::Note]
        # @return [void]
        def save(note)
          raise NotImplementedError, "#{self.class} must implement #save"
        end

        # @param path [ValueObjects::NotePath]
        # @return [Entities::Note, nil]
        def find_by_path(path)
          raise NotImplementedError, "#{self.class} must implement #find_by_path"
        end

        # @param folder [ValueObjects::FolderPath, nil]
        # @return [Array<Entities::Note>]
        def find_all(folder: nil)
          raise NotImplementedError, "#{self.class} must implement #find_all"
        end

        # @param path [ValueObjects::NotePath]
        # @return [Boolean]
        def exists?(path)
          raise NotImplementedError, "#{self.class} must implement #exists?"
        end

        # @param path [ValueObjects::NotePath]
        # @return [void]
        def delete(path)
          raise NotImplementedError, "#{self.class} must implement #delete"
        end

        # @return [Array<ValueObjects::FolderPath>]
        def list_folders
          raise NotImplementedError, "#{self.class} must implement #list_folders"
        end
      end
    end
  end
end
