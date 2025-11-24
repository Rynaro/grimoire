# frozen_string_literal: true

require_relative '../../domain/value_objects/note_path'
require_relative '../../domain/value_objects/note_content'
require_relative '../../domain/repositories/note_repository'

module Grimoire
  module Application
    module Services
      # Application service for updating note content
      class UpdateNoteService
        def initialize(note_repository)
          @note_repository = note_repository
        end

        def execute(path:, content:)
          note_path = path.is_a?(Domain::ValueObjects::NotePath) ? path : Domain::ValueObjects::NotePath.new(path)
          note_content = content.is_a?(Domain::ValueObjects::NoteContent) ? content : Domain::ValueObjects::NoteContent.new(content)

          note = @note_repository.find_by_path(note_path)
          raise ArgumentError, "Note does not exist: #{path}" unless note

          note.update_content(note_content)
          @note_repository.save(note)
          note
        end
      end
    end
  end
end
