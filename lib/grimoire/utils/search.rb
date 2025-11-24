# frozen_string_literal: true

module Grimoire
  module Utils
    class Search
      def initialize(file_manager)
        @file_manager = file_manager
      end

      def search_files(query)
        @file_manager.search_files(query)
      end

      def search_content(query)
        @file_manager.search_content(query)
      end
    end
  end
end
