# frozen_string_literal: true

module Grimoire
  module Application
    module UseCases
      # GetNote Use Case
      # Single Responsibility: Retrieving a single note
      class GetNote
        def initialize(repository)
          @repository = repository
        end

        # @param path [String, Domain::ValueObjects::NotePath]
        # @return [Domain::Entities::Note, nil]
        def call(path:)
          note_path = ensure_note_path(path)
          @repository.find_by_path(note_path)
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
