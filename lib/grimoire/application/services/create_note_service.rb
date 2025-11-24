# frozen_string_literal: true

require_relative '../../domain/entities/note'
require_relative '../../domain/value_objects/note_name'
require_relative '../../domain/value_objects/note_content'
require_relative '../../domain/repositories/note_repository'

module Grimoire
  module Application
    module Services
      # Application service for creating notes
      # Single Responsibility: Handles note creation use case
      class CreateNoteService
        def initialize(note_repository)
          @note_repository = note_repository
        end

        def execute(name:, folder: nil, content: '')
          note_name = Domain::ValueObjects::NoteName.new(name)
          note_path = note_name.to_path(folder)
          note_content = Domain::ValueObjects::NoteContent.new(content)

          # Check if note already exists
          if @note_repository.exists?(note_path)
            raise ArgumentError, "Note '#{name}' already exists"
          end

          note = Domain::Entities::Note.new(
            path: note_path,
            name: note_name,
            content: note_content
          )

          @note_repository.save(note)
          note
        end
      end
    end
  end
end
