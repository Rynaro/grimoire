# frozen_string_literal: true

require_relative '../value_objects/folder_name'

module Grimoire
  module Domain
    module Entities
      class Folder
        attr_reader :name, :path

        def initialize(name:, path: nil)
          @name = name.is_a?(ValueObjects::FolderName) ? name : ValueObjects::FolderName.new(name)
          @path = path || @name.to_s
        end

        def ==(other)
          other.is_a?(self.class) && @name == other.name
        end

        def eql?(other)
          self == other
        end

        def hash
          @name.hash
        end
      end
    end
  end
end
