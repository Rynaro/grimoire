# frozen_string_literal: true

require_relative '../value_objects/note_path'
require_relative '../value_objects/note_content'
require_relative '../value_objects/note_metadata'

module Grimoire
  module Domain
    module Entities
      # Note Entity - Aggregate Root
      # Represents a note in the system with identity and lifecycle
      class Note
        attr_reader :path, :metadata
        attr_accessor :content

        def initialize(path:, content:, metadata:)
          @path = path.is_a?(ValueObjects::NotePath) ? path : ValueObjects::NotePath.new(path)
          @content = content.is_a?(ValueObjects::NoteContent) ? content : ValueObjects::NoteContent.new(content)
          @metadata = metadata.is_a?(ValueObjects::NoteMetadata) ? metadata : ValueObjects::NoteMetadata.new(metadata)
        end

        # Entity identity is based on path
        def id
          @path.to_s
        end

        def name
          @metadata.name
        end

        def update_content(new_content)
          @content = ValueObjects::NoteContent.new(new_content)
          @metadata = @metadata.touch
        end

        def linked_notes
          @content.extract_links
        end

        def ==(other)
          other.is_a?(Note) && other.id == id
        end

        alias eql? ==

        def hash
          id.hash
        end

        def to_h
          {
            path: @path.to_s,
            name: name,
            content: @content.to_s,
            metadata: @metadata.to_h
          }
        end

        # Factory method for creating new notes
        def self.create(name:, folder: nil, content: '')
          path = ValueObjects::NotePath.from_name(name, folder)
          metadata = ValueObjects::NoteMetadata.new(
            name: name,
            modified_at: Time.now
          )
          content_vo = ValueObjects::NoteContent.new(content.empty? ? "# #{name}\n\n" : content)

          new(path: path, content: content_vo, metadata: metadata)
        end
      end
    end
  end
end
