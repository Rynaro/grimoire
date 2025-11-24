# frozen_string_literal: true

require 'dry-container'
require 'dry-auto_inject'

# Load all domain, application, and infrastructure components
require_relative 'domain/entities/note'
require_relative 'domain/repositories/note_repository'
require_relative 'domain/services/note_search_service'
require_relative 'infrastructure/persistence/file_system_note_repository'
require_relative 'infrastructure/rendering/markdown_renderer'
require_relative 'infrastructure/rendering/terminal_formatter'
require_relative 'application/use_cases/create_note'
require_relative 'application/use_cases/update_note'
require_relative 'application/use_cases/delete_note'
require_relative 'application/use_cases/list_notes'
require_relative 'application/use_cases/search_notes'
require_relative 'application/use_cases/get_note'

module Grimoire
  # Dependency Injection Container
  # Follows Dependency Inversion Principle
  # Single source of truth for object creation and dependencies
  class Container
    extend Dry::Container::Mixin

    # Infrastructure - Repositories
    register :note_repository do
      Infrastructure::Persistence::FileSystemNoteRepository.new
    end

    # Infrastructure - Rendering
    register :markdown_renderer do
      Infrastructure::Rendering::MarkdownRenderer.new
    end

    register :terminal_formatter do
      Infrastructure::Rendering::TerminalFormatter.new
    end

    # Application - Use Cases
    register :create_note_use_case do
      Application::UseCases::CreateNote.new(resolve(:note_repository))
    end

    register :update_note_use_case do
      Application::UseCases::UpdateNote.new(resolve(:note_repository))
    end

    register :delete_note_use_case do
      Application::UseCases::DeleteNote.new(resolve(:note_repository))
    end

    register :list_notes_use_case do
      Application::UseCases::ListNotes.new(resolve(:note_repository))
    end

    register :search_notes_use_case do
      Application::UseCases::SearchNotes.new(resolve(:note_repository))
    end

    register :get_note_use_case do
      Application::UseCases::GetNote.new(resolve(:note_repository))
    end
  end

  # Auto-injection helper
  Import = Dry::AutoInject(Container)
end
