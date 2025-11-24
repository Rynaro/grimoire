# frozen_string_literal: true

module Grimoire
  module Domain
    module Services
      # NoteSearchService - Domain Service
      # Handles complex search logic that doesn't belong to a single entity
      class NoteSearchService
        def initialize(repository)
          @repository = repository
        end

        # Search notes by name
        # @param query [String]
        # @param folder [ValueObjects::FolderPath, nil]
        # @return [Array<Entities::Note>]
        def search_by_name(query, folder: nil)
          notes = @repository.find_all(folder: folder)
          return notes if query.nil? || query.strip.empty?

          query_downcase = query.downcase
          notes.select { |note| note.name.downcase.include?(query_downcase) }
        end

        # Search notes by content
        # @param query [String]
        # @param folder [ValueObjects::FolderPath, nil]
        # @return [Array<Hash>] Array of {note:, matches: [{line_number:, content:}]}
        def search_by_content(query, folder: nil)
          return [] if query.nil? || query.strip.empty?

          notes = @repository.find_all(folder: folder)
          results = []

          notes.each do |note|
            matches = note.content.search_lines(query)
            results << { note: note, matches: matches } unless matches.empty?
          end

          results
        end

        # Find notes that link to the given note
        # @param note [Entities::Note]
        # @return [Array<Entities::Note>]
        def find_backlinks(note)
          all_notes = @repository.find_all
          all_notes.select do |other_note|
            other_note.linked_notes.include?(note.name)
          end
        end

        # Find all notes linked from the given note
        # @param note [Entities::Note]
        # @return [Array<Entities::Note>]
        def find_forward_links(note)
          linked_names = note.linked_notes
          all_notes = @repository.find_all
          
          all_notes.select do |other_note|
            linked_names.any? { |name| other_note.name.downcase == name.downcase }
          end
        end
      end
    end
  end
end
