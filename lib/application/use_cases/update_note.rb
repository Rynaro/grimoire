# frozen_string_literal: true

module Grimoire
  module Application
    module UseCases
      # UpdateNote Use Case
      # Single Responsibility: Updating existing notes
      class UpdateNote
        def initialize(repository)
          @repository = repository
        end

        # @param path [String, Domain::ValueObjects::NotePath]
        # @param content [String]
        # @return [Domain::Entities::Note]
        def call(path:, content:)
          note_path = ensure_note_path(path)
          
          note = @repository.find_by_path(note_path)
          raise ArgumentError, "Note not found: #{note_path}" unless note

          note.update_content(content)
          @repository.save(note)
          
          note
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
