# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      class FolderName
        attr_reader :value

        INVALID_CHARS = /[<>:"|?*\x00-\x1f]/.freeze

        def initialize(value)
          raise ArgumentError, 'Folder name cannot be nil' if value.nil?
          
          name = value.to_s.strip
          raise ArgumentError, 'Folder name cannot be empty' if name.empty?
          raise ArgumentError, "Folder name contains invalid characters: #{name}" if name.match?(INVALID_CHARS)

          @value = name.freeze
        end

        def to_s
          @value
        end

        def ==(other)
          other.is_a?(self.class) && @value == other.value
        end

        def eql?(other)
          self == other
        end

        def hash
          @value.hash
        end
      end
    end
  end
end
