# frozen_string_literal: true

module Grimoire
  module Domain
    module Repositories
      # Repository interface for Note persistence
      # Following Dependency Inversion Principle - depend on abstraction
      class NoteRepository
        def find_by_path(path)
          raise NotImplementedError, 'Subclasses must implement find_by_path'
        end

        def find_all
          raise NotImplementedError, 'Subclasses must implement find_all'
        end

        def find_by_folder(folder_name)
          raise NotImplementedError, 'Subclasses must implement find_by_folder'
        end

        def save(note)
          raise NotImplementedError, 'Subclasses must implement save'
        end

        def delete(path)
          raise NotImplementedError, 'Subclasses must implement delete'
        end

        def exists?(path)
          raise NotImplementedError, 'Subclasses must implement exists?'
        end

        def search_content(query)
          raise NotImplementedError, 'Subclasses must implement search_content'
        end
      end
    end
  end
end
