# frozen_string_literal: true

module Grimoire
  module Domain
    module Repositories
      # Repository interface for Folder persistence
      class FolderRepository
        def find_all
          raise NotImplementedError, 'Subclasses must implement find_all'
        end

        def find_by_name(name)
          raise NotImplementedError, 'Subclasses must implement find_by_name'
        end

        def save(folder)
          raise NotImplementedError, 'Subclasses must implement save'
        end

        def delete(name)
          raise NotImplementedError, 'Subclasses must implement delete'
        end

        def exists?(name)
          raise NotImplementedError, 'Subclasses must implement exists?'
        end
      end
    end
  end
end
