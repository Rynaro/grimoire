# frozen_string_literal: true

module Grimoire
  module Application
    module UseCases
      # CreateNote Use Case
      # Single Responsibility: Creating new notes
      # Depends on abstractions (repository interface), not concretions
      class CreateNote
        def initialize(repository)
          @repository = repository
        end

        # @param name [String]
        # @param folder [String, nil]
        # @param content [String]
        # @return [Domain::Entities::Note]
        def call(name:, folder: nil, content: '')
          validate_input(name)

          # Check if note already exists
          note = Domain::Entities::Note.create(
            name: name,
            folder: folder,
            content: content
          )

          if @repository.exists?(note.path)
            raise ArgumentError, "Note '#{name}' already exists"
          end

          @repository.save(note)
          note
        end

        private

        def validate_input(name)
          raise ArgumentError, 'Note name cannot be empty' if name.nil? || name.strip.empty?
          raise ArgumentError, 'Note name too long' if name.length > 255
        end
      end
    end
  end
end
