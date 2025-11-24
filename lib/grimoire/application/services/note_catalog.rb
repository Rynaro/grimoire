# frozen_string_literal: true

module Grimoire
  module Application
    module Services
      # Coordinates note-related use cases and shields the UI from persistence details.
      class NoteCatalog
        def initialize(repository:, link_resolver:)
          @repository = repository
          @link_resolver = link_resolver
        end

        def list_notes
          repository.list_notes
        end

        def folders
          repository.folders
        end

        def subfolders(parent = ".")
          repository.subfolders(parent)
        end

        def notes_in(folder = ".")
          repository.notes_in(folder)
        end

        def find_note(id)
          repository.find_note(id)
        end

        def create_note(folder:, title:)
          repository.create_note_in(folder:, title:)
        end

        def delete_note(id)
          repository.delete_note(id)
        end

        def create_folder(path)
          repository.create_folder(path)
        end

        def delete_folder(path)
          repository.delete_folder(path)
        end

        def resolve_link(reference, current_folder:)
          link_resolver.call(reference, current_folder:)
        end

        def relative_path(path)
          repository.relative_path(path)
        end

        def root_label
          File.basename(repository.root_path.to_s)
        rescue NoMethodError
          "Notes"
        end

        private

        attr_reader :repository, :link_resolver
      end
    end
  end
end
