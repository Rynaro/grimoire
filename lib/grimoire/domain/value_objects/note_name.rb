# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      class NoteName
        attr_reader :value

        INVALID_CHARS = /[<>:"|?*\x00-\x1f]/.freeze

        def initialize(value)
          raise ArgumentError, 'Name cannot be nil' if value.nil?
          
          name = value.to_s.strip
          raise ArgumentError, 'Name cannot be empty' if name.empty?
          raise ArgumentError, "Name contains invalid characters: #{name}" if name.match?(INVALID_CHARS)

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

        def to_path(folder = nil)
          path = folder ? "#{folder}/#{@value}.md" : "#{@value}.md"
          ValueObjects::NotePath.new(path)
        end
      end
    end
  end
end
