# frozen_string_literal: true

module Grimoire
  module Domain
    SearchResult = Struct.new(:note, :line_number, :line, keyword_init: true)
  end
end
