# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      # NoteContent Value Object
      # Represents the markdown content of a note
      class NoteContent
        attr_reader :text

        def initialize(text)
          @text = text.to_s
          freeze
        end

        def to_s
          @text
        end

        def lines
          @text.split("\n")
        end

        def empty?
          @text.strip.empty?
        end

        def length
          @text.length
        end

        def line_count
          lines.length
        end

        # Extract [[note links]] from content
        def extract_links
          @text.scan(/\[\[([^\]]+)\]\]/).flatten.uniq
        end

        def contains?(query)
          @text.downcase.include?(query.downcase)
        end

        def search_lines(query)
          results = []
          lines.each_with_index do |line, index|
            if line.downcase.include?(query.downcase)
              results << { line_number: index + 1, content: line.strip }
            end
          end
          results
        end

        def ==(other)
          other.is_a?(NoteContent) && other.text == text
        end

        alias eql? ==

        def hash
          text.hash
        end
      end
    end
  end
end
