# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      # FolderPath Value Object
      # Represents a folder path in the notes system
      class FolderPath
        attr_reader :value

        ALL_NOTES = 'All Notes'

        def initialize(path)
          @value = normalize(path)
          freeze
        end

        def self.all_notes
          new(ALL_NOTES)
        end

        def self.root
          new('')
        end

        def to_s
          @value
        end

        def display_name
          return ALL_NOTES if root? || all_notes?
          @value
        end

        def root?
          @value.empty? || @value == '.'
        end

        def all_notes?
          @value == ALL_NOTES
        end

        def join(subfolder)
          return self.class.new(subfolder) if root?
          self.class.new(File.join(@value, subfolder))
        end

        def ==(other)
          other.is_a?(FolderPath) && other.value == value
        end

        alias eql? ==

        def hash
          value.hash
        end

        private

        def normalize(path)
          return ALL_NOTES if path.nil? || path.to_s.strip.empty? || path == ALL_NOTES
          
          normalized = path.to_s.strip
          normalized = normalized.chomp('/')
          normalized
        end
      end
    end
  end
end
