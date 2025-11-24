# frozen_string_literal: true

module Grimoire
  module Application
    module UseCases
      # DeleteNote Use Case
      # Single Responsibility: Deleting notes
      class DeleteNote
        def initialize(repository)
          @repository = repository
        end

        # @param path [String, Domain::ValueObjects::NotePath]
        # @return [Boolean]
        def call(path:)
          note_path = ensure_note_path(path)
          
          unless @repository.exists?(note_path)
            raise ArgumentError, "Note not found: #{note_path}"
          end

          @repository.delete(note_path)
          true
        end

        private

        def ensure_note_path(path)
          return path if path.is_a?(Domain::ValueObjects::NotePath)
          Domain::ValueObjects::NotePath.new(path)
        end
      end
    end
  end
end
