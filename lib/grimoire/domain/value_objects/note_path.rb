# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      class NotePath
        attr_reader :value

        def initialize(value)
          raise ArgumentError, 'Path cannot be nil' if value.nil?
          raise ArgumentError, 'Path cannot be empty' if value.to_s.empty?

          @value = value.to_s.freeze
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

        def folder
          dir = File.dirname(@value)
          dir == '.' ? nil : dir
        end

        def name
          File.basename(@value, '.md')
        end

        def full_path(base_dir)
          File.join(base_dir, @value)
        end
      end
    end
  end
end
