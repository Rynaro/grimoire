package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"grimoire/internal/app"
	"grimoire/internal/storage"
)

func main() {
	// Set up notes directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
		os.Exit(1)
	}

	notesDir := homeDir + "/.grimoire"
	if len(os.Args) > 1 {
		notesDir = os.Args[1]
	}

	// Initialize storage
	store := storage.NewFileStorage(notesDir)
	if err := store.Initialize(); err != nil {
		fmt.Fprintf(os.Stderr, "Error initializing storage: %v\n", err)
		os.Exit(1)
	}

	// Create and run the app
	p := tea.NewProgram(
		app.New(store),
		tea.WithAltScreen(),
		tea.WithMouseCellMotion(),
	)

	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error running app: %v\n", err)
		os.Exit(1)
	}
}
