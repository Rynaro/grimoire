package storage

import (
	"os"
	"path/filepath"
	"testing"
)

func TestFileStorage_Initialize(t *testing.T) {
	// Create temporary directory
	tmpDir := t.TempDir()
	
	// Create storage
	storage := NewFileStorage(tmpDir)
	
	// Initialize
	err := storage.Initialize()
	if err != nil {
		t.Fatalf("Initialize failed: %v", err)
	}
	
	// Check if directory exists
	if _, err := os.Stat(tmpDir); os.IsNotExist(err) {
		t.Errorf("Base directory was not created")
	}
	
	// Check if welcome note was created
	welcomePath := filepath.Join(tmpDir, "Welcome.md")
	if _, err := os.Stat(welcomePath); os.IsNotExist(err) {
		t.Errorf("Welcome note was not created")
	}
}

func TestFileStorage_CreateNote(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create a note
	path, err := storage.CreateNote("", "Test Note")
	if err != nil {
		t.Fatalf("CreateNote failed: %v", err)
	}
	
	// Check if file exists
	if _, err := os.Stat(path); os.IsNotExist(err) {
		t.Errorf("Note file was not created")
	}
	
	// Check if .md extension was added
	if filepath.Ext(path) != ".md" {
		t.Errorf("Expected .md extension, got %s", filepath.Ext(path))
	}
}

func TestFileStorage_SaveAndGetNote(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create a note
	path, _ := storage.CreateNote("", "Test Note")
	
	// Save content
	content := "# Test Content\n\nThis is a test."
	err := storage.SaveNote(path, content)
	if err != nil {
		t.Fatalf("SaveNote failed: %v", err)
	}
	
	// Get note
	note, err := storage.GetNote(path)
	if err != nil {
		t.Fatalf("GetNote failed: %v", err)
	}
	
	// Check content
	if note.Content != content {
		t.Errorf("Expected content %q, got %q", content, note.Content)
	}
}

func TestFileStorage_CreateFolder(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create a folder
	path, err := storage.CreateFolder("", "TestFolder")
	if err != nil {
		t.Fatalf("CreateFolder failed: %v", err)
	}
	
	// Check if directory exists
	info, err := os.Stat(path)
	if os.IsNotExist(err) {
		t.Errorf("Folder was not created")
	}
	if !info.IsDir() {
		t.Errorf("Created path is not a directory")
	}
}

func TestFileStorage_GetNotes(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create some notes
	storage.CreateNote("", "Note1")
	storage.CreateNote("", "Note2")
	storage.CreateFolder("", "Folder1")
	
	// Get notes
	notes, err := storage.GetNotes("")
	if err != nil {
		t.Fatalf("GetNotes failed: %v", err)
	}
	
	// Should have at least 4 items (Welcome.md + Note1.md + Note2.md + Folder1)
	if len(notes) < 4 {
		t.Errorf("Expected at least 4 notes, got %d", len(notes))
	}
}

func TestFileStorage_SearchNotes(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create notes with specific names
	storage.CreateNote("", "Project Alpha")
	storage.CreateNote("", "Project Beta")
	storage.CreateNote("", "Personal Notes")
	
	// Search for "project"
	results, err := storage.SearchNotes("project")
	if err != nil {
		t.Fatalf("SearchNotes failed: %v", err)
	}
	
	// Should find 2 notes
	if len(results) < 2 {
		t.Errorf("Expected at least 2 results for 'project', got %d", len(results))
	}
}

func TestFileStorage_SearchContent(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create notes with specific content
	path1, _ := storage.CreateNote("", "Note1")
	storage.SaveNote(path1, "This contains the keyword golang")
	
	path2, _ := storage.CreateNote("", "Note2")
	storage.SaveNote(path2, "This is about python programming")
	
	// Search for "golang"
	results, err := storage.SearchContent("golang")
	if err != nil {
		t.Fatalf("SearchContent failed: %v", err)
	}
	
	// Should find 1 note
	if len(results) != 1 {
		t.Errorf("Expected 1 result for 'golang', got %d", len(results))
	}
}

func TestFileStorage_DeleteNote(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create a note
	path, _ := storage.CreateNote("", "ToDelete")
	
	// Delete it
	err := storage.DeleteNote(path)
	if err != nil {
		t.Fatalf("DeleteNote failed: %v", err)
	}
	
	// Check if it's gone
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Errorf("Note was not deleted")
	}
}

func TestFileStorage_DeleteFolder(t *testing.T) {
	tmpDir := t.TempDir()
	storage := NewFileStorage(tmpDir)
	storage.Initialize()
	
	// Create a folder with a note inside
	folderPath, _ := storage.CreateFolder("", "ToDelete")
	storage.CreateNote("ToDelete", "Note")
	
	// Delete folder
	err := storage.DeleteFolder(folderPath)
	if err != nil {
		t.Fatalf("DeleteFolder failed: %v", err)
	}
	
	// Check if it's gone
	if _, err := os.Stat(folderPath); !os.IsNotExist(err) {
		t.Errorf("Folder was not deleted")
	}
}
