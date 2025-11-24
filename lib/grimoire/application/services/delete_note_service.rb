# frozen_string_literal: true

require_relative '../../domain/value_objects/note_path'
require_relative '../../domain/repositories/note_repository'

module Grimoire
  module Application
    module Services
      # Application service for deleting notes
      class DeleteNoteService
        def initialize(note_repository)
          @note_repository = note_repository
        end

        def execute(path:)
          note_path = path.is_a?(Domain::ValueObjects::NotePath) ? path : Domain::ValueObjects::NotePath.new(path)
          
          unless @note_repository.exists?(note_path)
            raise ArgumentError, "Note does not exist: #{path}"
          end

          @note_repository.delete(note_path)
        end
      end
    end
  end
end
