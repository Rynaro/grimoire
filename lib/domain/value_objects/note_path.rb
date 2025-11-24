# frozen_string_literal: true

require 'pathname'

module Grimoire
  module Domain
    module ValueObjects
      # NotePath Value Object
      # Represents an immutable path to a note
      class NotePath
        attr_reader :value

        def initialize(path)
          @value = validate_and_normalize(path)
          freeze
        end

        def self.from_name(name, folder = nil)
          filename = sanitize_filename(name) + '.md'
          path = folder ? File.join(folder, filename) : filename
          new(path)
        end

        def to_s
          @value
        end

        def basename
          File.basename(@value, '.md')
        end

        def dirname
          dir = File.dirname(@value)
          dir == '.' ? nil : dir
        end

        def extension
          File.extname(@value)
        end

        def markdown?
          extension == '.md'
        end

        def ==(other)
          other.is_a?(NotePath) && other.value == value
        end

        alias eql? ==

        def hash
          value.hash
        end

        private

        def validate_and_normalize(path)
          raise ArgumentError, 'Path cannot be empty' if path.nil? || path.strip.empty?
          raise ArgumentError, 'Path cannot contain ../' if path.include?('../')
          
          normalized = path.strip
          normalized += '.md' unless normalized.end_with?('.md')
          normalized
        end

        def self.sanitize_filename(name)
          name.gsub(/[^0-9A-Za-z.\-_]/, '_')
        end
      end
    end
  end
end
