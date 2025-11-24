# frozen_string_literal: true

module Grimoire
  module Application
    module Services
      # Application service dedicated to searching note titles and bodies.
      class SearchNotes
        def initialize(repository)
          @repository = repository
        end

        def by_title(query)
          regex = regex_for(query)
          repository.list_notes.select { |note| note.title.match?(regex) || note.id.match?(regex) }
        end

        def by_content(query)
          regex = regex_for(query)
          repository.list_notes.each_with_object([]) do |note, results|
            note.content.each_line.with_index(1) do |line, number|
              next unless line.match?(regex)

              results << Grimoire::Domain::SearchResult.new(note:, line_number: number, line:)
            end
          end
        end

        private

        attr_reader :repository

        def regex_for(query)
          /#{Regexp.escape(query)}/i
        end
      end
    end
  end
end
