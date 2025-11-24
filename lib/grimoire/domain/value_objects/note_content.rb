# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      class NoteContent
        attr_reader :value

        def initialize(value = '')
          @value = (value || '').to_s.freeze
        end

        def to_s
          @value
        end

        def empty?
          @value.empty?
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
