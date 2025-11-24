# frozen_string_literal: true

require_relative '../value_objects/note_path'
require_relative '../value_objects/note_name'
require_relative '../value_objects/note_content'

module Grimoire
  module Domain
    module Entities
      class Note
        attr_reader :path, :name, :content, :modified_at

        def initialize(path:, name:, content: nil, modified_at: nil)
          @path = path.is_a?(ValueObjects::NotePath) ? path : ValueObjects::NotePath.new(path)
          @name = name.is_a?(ValueObjects::NoteName) ? name : ValueObjects::NoteName.new(name)
          @content = content.is_a?(ValueObjects::NoteContent) ? content : ValueObjects::NoteContent.new(content)
          @modified_at = modified_at || Time.now
        end

        def update_content(new_content)
          @content = new_content.is_a?(ValueObjects::NoteContent) ? new_content : ValueObjects::NoteContent.new(new_content)
          @modified_at = Time.now
          self
        end

        def folder
          @path.folder
        end

        def ==(other)
          other.is_a?(self.class) && @path == other.path
        end

        def eql?(other)
          self == other
        end

        def hash
          @path.hash
        end
      end
    end
  end
end
