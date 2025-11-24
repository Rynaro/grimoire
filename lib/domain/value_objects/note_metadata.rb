# frozen_string_literal: true

module Grimoire
  module Domain
    module ValueObjects
      # NoteMetadata Value Object
      # Represents metadata about a note
      class NoteMetadata
        attr_reader :name, :modified_at, :created_at, :tags

        def initialize(name:, modified_at: Time.now, created_at: nil, tags: [])
          @name = name.to_s
          @modified_at = modified_at
          @created_at = created_at || modified_at
          @tags = tags.freeze
          freeze
        end

        def touch
          self.class.new(
            name: @name,
            modified_at: Time.now,
            created_at: @created_at,
            tags: @tags
          )
        end

        def with_tags(new_tags)
          self.class.new(
            name: @name,
            modified_at: @modified_at,
            created_at: @created_at,
            tags: new_tags
          )
        end

        def age_in_days
          ((Time.now - @modified_at) / 86400).to_i
        end

        def recent?(days = 7)
          age_in_days <= days
        end

        def to_h
          {
            name: @name,
            modified_at: @modified_at,
            created_at: @created_at,
            tags: @tags
          }
        end

        def ==(other)
          other.is_a?(NoteMetadata) &&
            other.name == name &&
            other.modified_at == modified_at &&
            other.created_at == created_at &&
            other.tags == tags
        end

        alias eql? ==

        def hash
          [name, modified_at, created_at, tags].hash
        end
      end
    end
  end
end
