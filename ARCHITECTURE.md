# Grimoire Architecture

This document describes the Domain-Driven Design (DDD) and SOLID principles architecture of the Grimoire application.

## Architecture Overview

Grimoire follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│     Presentation Layer (TUI)        │
│  - Application (main controller)     │
│  - Components (Sidebar, NoteArea)    │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│     Application Layer                │
│  - ServiceContainer (DI Container)   │
│  - Application Services (Use Cases)  │
│    * CreateNoteService              │
│    * UpdateNoteService              │
│    * DeleteNoteService              │
│    * SearchNotesService             │
│    * CreateFolderService            │
│    * DeleteFolderService            │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│     Domain Layer                     │
│  - Entities (Note, Folder)          │
│  - Value Objects                    │
│    * NotePath, NoteName             │
│    * NoteContent, FolderName        │
│  - Domain Services                  │
│    * LinkExtractor                  │
│  - Repository Interfaces            │
│    * NoteRepository                 │
│    * FolderRepository               │
└─────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│     Infrastructure Layer             │
│  - FileSystemNoteRepository         │
│  - FileSystemFolderRepository       │
└─────────────────────────────────────┘
```

## Domain Layer

### Entities

**Note** - Represents a note with:
- `path` (NotePath value object)
- `name` (NoteName value object)
- `content` (NoteContent value object)
- `modified_at` (timestamp)
- Business logic: `update_content(new_content)`

**Folder** - Represents a folder with:
- `name` (FolderName value object)
- `path` (string)

### Value Objects

Value objects are immutable and validate their own data:

- **NotePath**: Validates and encapsulates note file paths
- **NoteName**: Validates note names (no invalid filesystem characters)
- **NoteContent**: Encapsulates note content
- **FolderName**: Validates folder names

### Domain Services

**LinkExtractor**: Extracts wiki-style and markdown links from note content. This is domain logic that doesn't belong to any single entity.

### Repository Interfaces

Abstract interfaces defining persistence contracts:
- `NoteRepository` - CRUD operations for notes
- `FolderRepository` - CRUD operations for folders

## Application Layer

### Application Services

Each service handles a single use case (Single Responsibility Principle):

- **CreateNoteService**: Creates a new note
- **UpdateNoteService**: Updates note content
- **DeleteNoteService**: Deletes a note
- **SearchNotesService**: Searches notes by name or content
- **CreateFolderService**: Creates a new folder
- **DeleteFolderService**: Deletes a folder

### Service Container

Dependency Injection container that:
- Instantiates repositories (infrastructure)
- Instantiates application services
- Provides services to the presentation layer

## Infrastructure Layer

### Repositories

Concrete implementations of repository interfaces:

- **FileSystemNoteRepository**: Persists notes to the filesystem
- **FileSystemFolderRepository**: Manages folders on the filesystem

These implementations handle:
- File I/O operations
- Path resolution
- Directory management

## SOLID Principles Applied

### Single Responsibility Principle (SRP)

- Each application service handles one use case
- Value objects encapsulate single concepts
- Entities contain only domain logic
- Repositories handle only persistence

### Open/Closed Principle (OCP)

- Repository interfaces allow new implementations without modifying existing code
- Can add new repository implementations (e.g., DatabaseNoteRepository) without changing application services

### Liskov Substitution Principle (LSP)

- All repository implementations are substitutable through their interfaces
- Application services depend on abstractions, not concrete implementations

### Interface Segregation Principle (ISP)

- Separate interfaces for NoteRepository and FolderRepository
- Each interface contains only methods relevant to its domain

### Dependency Inversion Principle (DIP)

- Application services depend on repository interfaces, not implementations
- ServiceContainer injects concrete implementations
- Presentation layer depends on application services, not domain entities directly

## Benefits of This Architecture

1. **Testability**: Easy to mock repositories for testing
2. **Maintainability**: Clear separation of concerns
3. **Extensibility**: Easy to add new features or change implementations
4. **Domain Focus**: Business logic is isolated in the domain layer
5. **Type Safety**: Value objects provide validation and type safety

## Data Flow Example: Creating a Note

1. **User Input**: User presses 'n' in TUI
2. **Application Layer**: `Application#create_new_note` collects name
3. **Application Service**: Calls `CreateNoteService#execute`
4. **Domain Layer**: Service creates `NoteName` and `NotePath` value objects (validation happens here)
5. **Domain Layer**: Service creates `Note` entity
6. **Infrastructure Layer**: Service calls `NoteRepository#save`
7. **File System**: Repository writes to filesystem
8. **UI Update**: Application refreshes sidebar and loads note

## Future Extensibility

This architecture makes it easy to:

- Add a database repository without changing application services
- Add new value objects for validation
- Add new domain services for complex business logic
- Add new application services for new use cases
- Replace the TUI with a web interface (just change presentation layer)
