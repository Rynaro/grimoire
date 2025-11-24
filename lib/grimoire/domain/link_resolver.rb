# frozen_string_literal: true

module Grimoire
  module Domain
    # Domain service that understands how to interpret [[links]] within a note.
    class LinkResolver
      def initialize(notes_repository)
        @notes_repository = notes_repository
      end

      def call(reference, current_folder: ".")
        notes_repository.resolve_link(reference, current_folder:)
      end

      private

      attr_reader :notes_repository
    end
  end
end
