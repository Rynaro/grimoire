package app

import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"grimoire/internal/storage"
)

// Messages
type foldersLoadedMsg struct {
	folders []storage.Note
}

type notesLoadedMsg struct {
	notes []storage.Note
}

type noteLoadedMsg struct {
	note storage.Note
}

type errorMsg struct {
	err error
}

// Commands
func (m Model) loadFolders() tea.Msg {
	folders, err := m.storage.GetFolders()
	if err != nil {
		return errorMsg{err}
	}
	return foldersLoadedMsg{folders}
}

func (m Model) loadNotes() tea.Msg {
	notes, err := m.storage.GetNotes(m.currentFolder)
	if err != nil {
		return errorMsg{err}
	}
	return notesLoadedMsg{notes}
}

func (m Model) loadCurrentNote() tea.Msg {
	if m.noteIndex < 0 || m.noteIndex >= len(m.notes) {
		return nil
	}

	note := m.notes[m.noteIndex]
	if note.IsFolder {
		return noteLoadedMsg{note}
	}

	fullNote, err := m.storage.GetNote(note.Path)
	if err != nil {
		return errorMsg{err}
	}

	return noteLoadedMsg{fullNote}
}

// View mode handlers
func (m Model) updateView(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg.String() {
	case "q":
		return m, tea.Quit

	case "tab":
		// Cycle through panes
		m.activePane = (m.activePane + 1) % 3
		return m, nil

	case "shift+tab":
		// Cycle backwards through panes
		m.activePane = (m.activePane + 2) % 3
		return m, nil

	case "up", "k":
		switch m.activePane {
		case PaneFolders:
			if m.folderIndex > -1 {
				m.folderIndex--
				m.currentFolder = m.getFolderName()
				cmds = append(cmds, m.loadNotes)
			}
		case PaneNotes:
			if m.noteIndex > 0 {
				m.noteIndex--
				cmds = append(cmds, m.loadCurrentNote)
			}
		case PaneContent:
			m.viewport.LineUp(1)
		}

	case "down", "j":
		switch m.activePane {
		case PaneFolders:
			if m.folderIndex < len(m.folders)-1 {
				m.folderIndex++
				m.currentFolder = m.getFolderName()
				cmds = append(cmds, m.loadNotes)
			}
		case PaneNotes:
			if m.noteIndex < len(m.notes)-1 {
				m.noteIndex++
				cmds = append(cmds, m.loadCurrentNote)
			}
		case PaneContent:
			m.viewport.LineDown(1)
		}

	case "pgup":
		if m.activePane == PaneContent {
			m.viewport.ViewUp()
		}

	case "pgdown":
		if m.activePane == PaneContent {
			m.viewport.ViewDown()
		}

	case "g":
		switch m.activePane {
		case PaneNotes:
			m.noteIndex = 0
			cmds = append(cmds, m.loadCurrentNote)
		case PaneContent:
			m.viewport.GotoTop()
		}

	case "G":
		switch m.activePane {
		case PaneNotes:
			if len(m.notes) > 0 {
				m.noteIndex = len(m.notes) - 1
				cmds = append(cmds, m.loadCurrentNote)
			}
		case PaneContent:
			m.viewport.GotoBottom()
		}

	case "enter":
		if m.activePane == PaneNotes && m.noteIndex >= 0 && m.noteIndex < len(m.notes) {
			note := m.notes[m.noteIndex]
			if note.IsFolder {
				// Navigate into folder
				if fs, ok := m.storage.(*storage.FileStorage); ok {
					m.currentFolder = note.Path[len(fs.BaseDir)+1:]
					m.noteIndex = 0
					cmds = append(cmds, m.loadNotes)
				}
			}
		}

	case "backspace":
		if m.currentFolder != "" {
			// Navigate up to parent folder
			parts := strings.Split(m.currentFolder, "/")
			if len(parts) > 1 {
				m.currentFolder = strings.Join(parts[:len(parts)-1], "/")
			} else {
				m.currentFolder = ""
			}
			m.noteIndex = 0
			m.folderIndex = -1
			cmds = append(cmds, m.loadNotes)
		}

	case "e":
		// Enter edit mode
		if m.currentNote != nil && !m.currentNote.IsFolder {
			m.mode = ModeEdit
			m.textarea.SetValue(m.currentNote.Content)
			m.textarea.Focus()
			cmds = append(cmds, m.textarea.Focus())
		}

	case "n":
		// Create new note
		m.mode = ModeCreateNote
		m.createInput.Reset()
		m.createInput.Focus()
		cmds = append(cmds, m.createInput.Focus())

	case "N":
		// Create new folder
		m.mode = ModeCreateFolder
		m.createInput.Reset()
		m.createInput.Focus()
		cmds = append(cmds, m.createInput.Focus())

	case "d":
		// Delete note/folder
		if m.currentNote != nil {
			m.mode = ModeDelete
		}

	case "/":
		// Search notes
		m.mode = ModeSearch
		m.searchInput.Reset()
		m.searchInput.Focus()
		cmds = append(cmds, m.searchInput.Focus())

	case "?":
		// Search content
		m.mode = ModeSearchContent
		m.searchInput.Reset()
		m.searchInput.Focus()
		cmds = append(cmds, m.searchInput.Focus())
	}

	return m, tea.Batch(cmds...)
}

// Edit mode handlers
func (m Model) updateEdit(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg.String() {
	case "esc":
		// Save and exit edit mode
		if m.currentNote != nil {
			content := m.textarea.Value()
			if err := m.storage.SaveNote(m.currentNote.Path, content); err != nil {
				m.err = err
			} else {
				m.currentNote.Content = content
				m.renderCurrentNote()
				m.statusMessage = "✓ Saved"
			}
		}
		m.mode = ModeView
		m.textarea.Blur()
		return m, nil

	case "ctrl+s":
		// Quick save
		if m.currentNote != nil {
			content := m.textarea.Value()
			if err := m.storage.SaveNote(m.currentNote.Path, content); err != nil {
				m.err = err
			} else {
				m.currentNote.Content = content
				m.statusMessage = "✓ Saved"
			}
		}
		return m, nil
	}

	m.textarea, cmd = m.textarea.Update(msg)
	return m, cmd
}

// Search mode handlers
func (m Model) updateSearch(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg.String() {
	case "esc":
		m.mode = ModeView
		m.searchInput.Blur()
		return m, nil

	case "enter":
		query := m.searchInput.Value()
		if query != "" {
			var results []storage.Note
			var err error

			if m.mode == ModeSearchContent {
				results, err = m.storage.SearchContent(query)
			} else {
				results, err = m.storage.SearchNotes(query)
			}

			if err != nil {
				m.err = err
			} else {
				m.notes = results
				if len(results) > 0 {
					m.noteIndex = 0
					m.statusMessage = "Found " + string(rune(len(results))) + " results"
				} else {
					m.statusMessage = "No results found"
				}
			}
		}
		m.mode = ModeView
		m.searchInput.Blur()
		return m, m.loadCurrentNote
	}

	m.searchInput, cmd = m.searchInput.Update(msg)
	return m, cmd
}

// Create mode handlers
func (m Model) updateCreate(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg.String() {
	case "esc":
		m.mode = ModeView
		m.createInput.Blur()
		return m, nil

	case "enter":
		name := m.createInput.Value()
		if name != "" {
			var path string
			var err error

			if m.mode == ModeCreateFolder {
				path, err = m.storage.CreateFolder(m.currentFolder, name)
				if err == nil {
					m.statusMessage = "✓ Folder created"
				}
			} else {
				path, err = m.storage.CreateNote(m.currentFolder, name)
				if err == nil {
					m.statusMessage = "✓ Note created"
				}
			}

			if err != nil {
				m.err = err
				m.statusMessage = "✗ Error: " + err.Error()
			} else {
				// Reload and select new item
				_ = path
			}
		}
		m.mode = ModeView
		m.createInput.Blur()
		return m, tea.Batch(m.loadFolders, m.loadNotes)
	}

	m.createInput, cmd = m.createInput.Update(msg)
	return m, cmd
}

// Delete mode handlers
func (m Model) updateDelete(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "y", "Y":
		// Confirm deletion
		if m.currentNote != nil {
			var err error
			if m.currentNote.IsFolder {
				err = m.storage.DeleteFolder(m.currentNote.Path)
			} else {
				err = m.storage.DeleteNote(m.currentNote.Path)
			}

			if err != nil {
				m.statusMessage = "✗ Error: " + err.Error()
			} else {
				m.statusMessage = "✓ Deleted"
				m.currentNote = nil
				if m.noteIndex >= len(m.notes)-1 && m.noteIndex > 0 {
					m.noteIndex--
				}
			}
		}
		m.mode = ModeView
		return m, tea.Batch(m.loadFolders, m.loadNotes)

	case "n", "N", "esc":
		// Cancel deletion
		m.mode = ModeView
		return m, nil
	}

	return m, nil
}

func (m Model) viewEdit() string {
	help := "Esc to save and exit • Ctrl+S to save • Editing: " + m.currentNote.Name
	helpStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("240")).
		Padding(0, 1)

	return lipgloss.JoinVertical(
		lipgloss.Left,
		helpStyle.Render(help),
		m.textarea.View(),
	)
}

func (m Model) viewSearch() string {
	prompt := "Search notes by name"
	if m.mode == ModeSearchContent {
		prompt = "Search notes by content"
	}

	promptStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("170")).
		Padding(1, 2)

	return lipgloss.JoinVertical(
		lipgloss.Left,
		promptStyle.Render(prompt),
		lipgloss.NewStyle().Padding(0, 2).Render(m.searchInput.View()),
	)
}

func (m Model) viewCreate() string {
	prompt := "Create new note"
	if m.mode == ModeCreateFolder {
		prompt = "Create new folder"
	}

	promptStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("170")).
		Padding(1, 2)

	return lipgloss.JoinVertical(
		lipgloss.Left,
		promptStyle.Render(prompt),
		lipgloss.NewStyle().Padding(0, 2).Render(m.createInput.View()),
	)
}

func (m Model) viewDelete() string {
	name := "this item"
	if m.currentNote != nil {
		name = m.currentNote.Name
	}

	prompt := "Delete " + name + "? (y/n)"

	promptStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("196")).
		Padding(1, 2)

	return promptStyle.Render(prompt)
}

func (m Model) getFolderName() string {
	if m.folderIndex < 0 || m.folderIndex >= len(m.folders) {
		return ""
	}
	return m.folders[m.folderIndex].Name
}
