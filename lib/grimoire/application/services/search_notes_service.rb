# frozen_string_literal: true

require_relative '../../domain/repositories/note_repository'
require_relative '../../domain/repositories/folder_repository'

module Grimoire
  module Application
    module Services
      # Application service for searching notes
      class SearchNotesService
        def initialize(note_repository, folder_repository)
          @note_repository = note_repository
          @folder_repository = folder_repository
        end

        def search_by_name(query)
          all_items = list_all_items
          query_lower = query.downcase
          
          all_items.select do |item|
            item[:name].downcase.include?(query_lower)
          end
        end

        def search_by_content(query)
          results = @note_repository.search_content(query)
          
          results.map do |result|
            note = result[:note]
            {
              type: :note,
              name: note.name.to_s,
              path: note.path.to_s,
              folder: note.folder,
              matches: result[:matches],
              note: note
            }
          end
        end

        def list_all_items
          items = []
          
          # Add folders
          @folder_repository.find_all.each do |folder|
            items << {
              type: :folder,
              name: folder.name.to_s,
              path: folder.path
            }
          end

          # Add root notes
          @note_repository.find_all.select { |n| n.folder.nil? }.each do |note|
            items << {
              type: :note,
              name: note.name.to_s,
              path: note.path.to_s,
              folder: nil,
              modified: note.modified_at,
              note: note
            }
          end

          # Add notes in folders
          @folder_repository.find_all.each do |folder|
            @note_repository.find_by_folder(folder.name.to_s).each do |note|
              items << {
                type: :note,
                name: note.name.to_s,
                path: note.path.to_s,
                folder: folder.name.to_s,
                modified: note.modified_at,
                note: note
              }
            end
          end

          items.sort_by do |item|
            [item[:type] == :folder ? 0 : 1, item[:name]]
          end
        end
      end
    end
  end
end
