# frozen_string_literal: true

require_relative 'grimoire/version'
require_relative 'grimoire/application'
require_relative 'grimoire/application/service_container'
require_relative 'grimoire/components/sidebar'
require_relative 'grimoire/components/note_area'
require_relative 'grimoire/utils/markdown_renderer'

# Domain layer
require_relative 'grimoire/domain/value_objects/note_path'
require_relative 'grimoire/domain/value_objects/note_name'
require_relative 'grimoire/domain/value_objects/note_content'
require_relative 'grimoire/domain/value_objects/folder_name'
require_relative 'grimoire/domain/entities/note'
require_relative 'grimoire/domain/entities/folder'
require_relative 'grimoire/domain/services/link_extractor'
require_relative 'grimoire/domain/repositories/note_repository'
require_relative 'grimoire/domain/repositories/folder_repository'

# Infrastructure layer
require_relative 'grimoire/infrastructure/repositories/file_system_note_repository'
require_relative 'grimoire/infrastructure/repositories/file_system_folder_repository'

# Application services
require_relative 'grimoire/application/services/create_note_service'
require_relative 'grimoire/application/services/delete_note_service'
require_relative 'grimoire/application/services/update_note_service'
require_relative 'grimoire/application/services/search_notes_service'
require_relative 'grimoire/application/services/create_folder_service'
require_relative 'grimoire/application/services/delete_folder_service'

module Grimoire
  class Error < StandardError; end
end
