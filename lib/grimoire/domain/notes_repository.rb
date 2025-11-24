# frozen_string_literal: true

module Grimoire
  module Domain
    # Abstraction for persisting and querying notes regardless of storage engine.
    module NotesRepository
      def list_notes
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def root_path
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def folders
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def subfolders(_relative_folder = ".")
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def notes_in(_relative_folder = ".")
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def find_note(_relative_path)
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def create_note_in(folder:, title:)
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def delete_note(_relative_path)
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def create_folder(_relative_path)
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def delete_folder(_relative_path)
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def resolve_link(reference, current_folder: ".")
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end

      def relative_path(_path)
        raise NotImplementedError, "#{self.class} must implement ##{__method__}"
      end
    end
  end
end
