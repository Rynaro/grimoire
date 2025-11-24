# frozen_string_literal: true

require_relative 'grimoire/version'
require_relative 'grimoire/application'
require_relative 'grimoire/components/sidebar'
require_relative 'grimoire/components/note_area'
require_relative 'grimoire/utils/file_manager'
require_relative 'grimoire/utils/markdown_renderer'
require_relative 'grimoire/utils/search'

module Grimoire
  class Error < StandardError; end
end
