package storage

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// Note represents a note in the system
type Note struct {
	Name     string
	Path     string
	Content  string
	Modified time.Time
	IsFolder bool
}

// Storage interface for note operations
type Storage interface {
	Initialize() error
	GetNotes(folder string) ([]Note, error)
	GetNote(path string) (Note, error)
	SaveNote(path, content string) error
	CreateNote(folder, name string) (string, error)
	CreateFolder(folder, name string) (string, error)
	DeleteNote(path string) error
	DeleteFolder(path string) error
	SearchNotes(query string) ([]Note, error)
	SearchContent(query string) ([]Note, error)
	GetFolders() ([]Note, error)
}

// FileStorage implements Storage using the filesystem
type FileStorage struct {
	BaseDir string
}

// NewFileStorage creates a new filesystem-based storage
func NewFileStorage(baseDir string) *FileStorage {
	return &FileStorage{
		BaseDir: baseDir,
	}
}

// Initialize creates the base directory if it doesn't exist
func (fs *FileStorage) Initialize() error {
	if err := os.MkdirAll(fs.BaseDir, 0755); err != nil {
		return fmt.Errorf("failed to create base directory: %w", err)
	}

	// Create a welcome note if directory is empty
	entries, err := os.ReadDir(fs.BaseDir)
	if err != nil {
		return err
	}

	if len(entries) == 0 {
		welcomePath := filepath.Join(fs.BaseDir, "Welcome.md")
		welcomeContent := `# Welcome to Grimoire 📖

Grimoire is your personal knowledge codex - a beautiful terminal-based note-taking application.

## Getting Started

- **n** - Create a new note
- **N** - Create a new folder
- **d** - Delete current note/folder
- **e** - Edit mode
- **Esc** - View mode
- **/** - Search notes
- **?** - Search content
- **Tab** - Switch between panes
- **↑/↓** - Navigate
- **q** - Quit

## Features

- 📁 Organize notes in folders
- ✨ Markdown support with beautiful rendering
- 🔗 Link between notes using [[note name]]
- 🔍 Powerful search across files and content
- ⚡ Lightning fast and resource efficient

## Philosophy

Your notes, your files, your sovereignty. Grimoire stores everything as plain markdown files in your filesystem at:

` + "`~/.grimoire/`" + `

Start creating your knowledge base now!
`
		if err := os.WriteFile(welcomePath, []byte(welcomeContent), 0644); err != nil {
			return fmt.Errorf("failed to create welcome note: %w", err)
		}
	}

	return nil
}

// GetFolders returns all folders in the notes directory
func (fs *FileStorage) GetFolders() ([]Note, error) {
	var folders []Note

	entries, err := os.ReadDir(fs.BaseDir)
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		if entry.IsDir() && !strings.HasPrefix(entry.Name(), ".") {
			info, err := entry.Info()
			if err != nil {
				continue
			}

			folders = append(folders, Note{
				Name:     entry.Name(),
				Path:     filepath.Join(fs.BaseDir, entry.Name()),
				IsFolder: true,
				Modified: info.ModTime(),
			})
		}
	}

	sort.Slice(folders, func(i, j int) bool {
		return folders[i].Name < folders[j].Name
	})

	return folders, nil
}

// GetNotes returns all notes in a folder
func (fs *FileStorage) GetNotes(folder string) ([]Note, error) {
	var notes []Note
	searchPath := fs.BaseDir

	if folder != "" {
		searchPath = filepath.Join(fs.BaseDir, folder)
	}

	entries, err := os.ReadDir(searchPath)
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		if strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		info, err := entry.Info()
		if err != nil {
			continue
		}

		note := Note{
			Name:     entry.Name(),
			Path:     filepath.Join(searchPath, entry.Name()),
			IsFolder: entry.IsDir(),
			Modified: info.ModTime(),
		}

		notes = append(notes, note)
	}

	// Sort: folders first, then by name
	sort.Slice(notes, func(i, j int) bool {
		if notes[i].IsFolder != notes[j].IsFolder {
			return notes[i].IsFolder
		}
		return notes[i].Name < notes[j].Name
	})

	return notes, nil
}

// GetNote retrieves a note's content
func (fs *FileStorage) GetNote(path string) (Note, error) {
	info, err := os.Stat(path)
	if err != nil {
		return Note{}, err
	}

	if info.IsDir() {
		return Note{
			Name:     filepath.Base(path),
			Path:     path,
			IsFolder: true,
			Modified: info.ModTime(),
		}, nil
	}

	content, err := os.ReadFile(path)
	if err != nil {
		return Note{}, err
	}

	return Note{
		Name:     filepath.Base(path),
		Path:     path,
		Content:  string(content),
		IsFolder: false,
		Modified: info.ModTime(),
	}, nil
}

// SaveNote saves a note's content
func (fs *FileStorage) SaveNote(path, content string) error {
	return os.WriteFile(path, []byte(content), 0644)
}

// CreateNote creates a new note
func (fs *FileStorage) CreateNote(folder, name string) (string, error) {
	if !strings.HasSuffix(name, ".md") {
		name += ".md"
	}

	path := filepath.Join(fs.BaseDir, folder, name)
	if folder == "" {
		path = filepath.Join(fs.BaseDir, name)
	}

	if _, err := os.Stat(path); err == nil {
		return "", fmt.Errorf("note already exists")
	}

	initialContent := fmt.Sprintf("# %s\n\n", strings.TrimSuffix(name, ".md"))
	if err := os.WriteFile(path, []byte(initialContent), 0644); err != nil {
		return "", err
	}

	return path, nil
}

// CreateFolder creates a new folder
func (fs *FileStorage) CreateFolder(folder, name string) (string, error) {
	path := filepath.Join(fs.BaseDir, folder, name)
	if folder == "" {
		path = filepath.Join(fs.BaseDir, name)
	}

	if err := os.MkdirAll(path, 0755); err != nil {
		return "", err
	}

	return path, nil
}

// DeleteNote deletes a note
func (fs *FileStorage) DeleteNote(path string) error {
	return os.Remove(path)
}

// DeleteFolder deletes a folder and all its contents
func (fs *FileStorage) DeleteFolder(path string) error {
	return os.RemoveAll(path)
}

// SearchNotes searches for notes by name
func (fs *FileStorage) SearchNotes(query string) ([]Note, error) {
	var results []Note
	query = strings.ToLower(query)

	err := filepath.Walk(fs.BaseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		if strings.HasPrefix(info.Name(), ".") {
			if info.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}

		if strings.Contains(strings.ToLower(info.Name()), query) {
			results = append(results, Note{
				Name:     info.Name(),
				Path:     path,
				IsFolder: info.IsDir(),
				Modified: info.ModTime(),
			})
		}

		return nil
	})

	return results, err
}

// SearchContent searches for notes containing specific content
func (fs *FileStorage) SearchContent(query string) ([]Note, error) {
	var results []Note
	query = strings.ToLower(query)

	err := filepath.Walk(fs.BaseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}

		if info.IsDir() || strings.HasPrefix(info.Name(), ".") {
			return nil
		}

		if !strings.HasSuffix(info.Name(), ".md") {
			return nil
		}

		content, err := os.ReadFile(path)
		if err != nil {
			return nil
		}

		if strings.Contains(strings.ToLower(string(content)), query) {
			results = append(results, Note{
				Name:     info.Name(),
				Path:     path,
				Content:  string(content),
				Modified: info.ModTime(),
			})
		}

		return nil
	})

	return results, err
}
