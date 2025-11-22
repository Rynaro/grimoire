package app

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/textarea"
	"github.com/charmbracelet/bubbles/textinput"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/lipgloss"
	"grimoire/internal/storage"
)

type Mode int

const (
	ModeView Mode = iota
	ModeEdit
	ModeSearch
	ModeSearchContent
	ModeCreateNote
	ModeCreateFolder
	ModeDelete
)

type Pane int

const (
	PaneFolders Pane = iota
	PaneNotes
	PaneContent
)

type Model struct {
	storage        storage.Storage
	folders        []storage.Note
	notes          []storage.Note
	currentFolder  string
	currentNote    *storage.Note
	folderIndex    int
	noteIndex      int
	activePane     Pane
	mode           Mode
	width          int
	height         int
	viewport       viewport.Model
	textarea       textarea.Model
	searchInput    textinput.Model
	createInput    textinput.Model
	renderer       *glamour.TermRenderer
	err            error
	statusMessage  string
}

// New creates a new app model
func New(store storage.Storage) Model {
	// Create viewport for content viewing
	vp := viewport.New(0, 0)
	vp.KeyMap = viewport.KeyMap{}

	// Create textarea for editing
	ta := textarea.New()
	ta.SetWidth(0)
	ta.SetHeight(0)
	ta.ShowLineNumbers = true
	ta.CharLimit = 0

	// Create search input
	si := textinput.New()
	si.Placeholder = "Search..."
	si.CharLimit = 100

	// Create input for note/folder creation
	ci := textinput.New()
	ci.Placeholder = "Enter name..."
	ci.CharLimit = 100

	// Create glamour renderer for markdown
	renderer, _ := glamour.NewTermRenderer(
		glamour.WithAutoStyle(),
		glamour.WithWordWrap(80),
	)

	m := Model{
		storage:      store,
		viewport:     vp,
		textarea:     ta,
		searchInput:  si,
		createInput:  ci,
		renderer:     renderer,
		activePane:   PaneNotes,
		mode:         ModeView,
		folderIndex:  -1,
		noteIndex:    0,
	}

	return m
}

func (m Model) Init() tea.Cmd {
	return tea.Batch(
		m.loadFolders,
		m.loadNotes,
		textarea.Blink,
	)
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		// Global quit
		if msg.String() == "ctrl+c" {
			return m, tea.Quit
		}

		// Mode-specific handling
		switch m.mode {
		case ModeEdit:
			return m.updateEdit(msg)
		case ModeSearch, ModeSearchContent:
			return m.updateSearch(msg)
		case ModeCreateNote, ModeCreateFolder:
			return m.updateCreate(msg)
		case ModeDelete:
			return m.updateDelete(msg)
		default:
			return m.updateView(msg)
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.updateSizes()
		if m.currentNote != nil && !m.currentNote.IsFolder {
			m.renderCurrentNote()
		}

	case foldersLoadedMsg:
		m.folders = msg.folders
		return m, nil

	case notesLoadedMsg:
		m.notes = msg.notes
		if len(m.notes) > 0 && m.noteIndex < 0 {
			m.noteIndex = 0
		}
		return m, m.loadCurrentNote

	case noteLoadedMsg:
		m.currentNote = &msg.note
		m.renderCurrentNote()
		return m, nil

	case errorMsg:
		m.err = msg.err
		return m, nil
	}

	return m, tea.Batch(cmds...)
}

func (m Model) View() string {
	if m.width == 0 {
		return "Loading..."
	}

	var content string

	switch m.mode {
	case ModeEdit:
		content = m.viewEdit()
	case ModeSearch, ModeSearchContent:
		content = m.viewSearch()
	case ModeCreateNote, ModeCreateFolder:
		content = m.viewCreate()
	case ModeDelete:
		content = m.viewDelete()
	default:
		content = m.viewMain()
	}

	// Status bar
	statusBar := m.viewStatusBar()

	return lipgloss.JoinVertical(
		lipgloss.Left,
		content,
		statusBar,
	)
}

func (m Model) viewMain() string {
	sidebarWidth := m.width / 5
	listWidth := m.width / 4
	contentWidth := m.width - sidebarWidth - listWidth - 4

	// Styles
	activeStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("170")).
		Background(lipgloss.Color("235"))

	folderStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("33"))

	normalStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("252"))

	paneBorderStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("238")).
		Padding(0, 1)

	activeBorderStyle := paneBorderStyle.Copy().
		BorderForeground(lipgloss.Color("170"))

	// Sidebar (Folders)
	var sidebarContent strings.Builder
	sidebarContent.WriteString(lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("170")).Render("📁 FOLDERS") + "\n\n")

	// Root folder
	rootStyle := normalStyle
	if m.activePane == PaneFolders && m.folderIndex == -1 {
		rootStyle = activeStyle
	}
	sidebarContent.WriteString(rootStyle.Render("📄 All Notes") + "\n")

	for i, folder := range m.folders {
		style := folderStyle
		if m.activePane == PaneFolders && m.folderIndex == i {
			style = activeStyle
		}
		sidebarContent.WriteString(style.Render(fmt.Sprintf("📁 %s", folder.Name)) + "\n")
	}

	sidebarBorder := paneBorderStyle
	if m.activePane == PaneFolders {
		sidebarBorder = activeBorderStyle
	}

	sidebar := sidebarBorder.
		Width(sidebarWidth - 4).
		Height(m.height - 4).
		Render(sidebarContent.String())

	// Notes List
	var listContent strings.Builder
	listContent.WriteString(lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("170")).Render("📝 NOTES") + "\n\n")

	if len(m.notes) == 0 {
		listContent.WriteString(lipgloss.NewStyle().Faint(true).Render("No notes found\n\nPress 'n' to create one"))
	} else {
		for i, note := range m.notes {
			icon := "📄"
			if note.IsFolder {
				icon = "📁"
			}

			style := normalStyle
			if m.activePane == PaneNotes && m.noteIndex == i {
				style = activeStyle
			}

			name := note.Name
			if len(name) > 25 {
				name = name[:22] + "..."
			}

			listContent.WriteString(style.Render(fmt.Sprintf("%s %s", icon, name)) + "\n")
		}
	}

	listBorder := paneBorderStyle
	if m.activePane == PaneNotes {
		listBorder = activeBorderStyle
	}

	notesList := listBorder.
		Width(listWidth - 4).
		Height(m.height - 4).
		Render(listContent.String())

	// Content Area
	contentBorder := paneBorderStyle
	if m.activePane == PaneContent {
		contentBorder = activeBorderStyle
	}

	var contentArea string
	if m.currentNote != nil && !m.currentNote.IsFolder {
		contentArea = contentBorder.
			Width(contentWidth - 4).
			Height(m.height - 4).
			Render(m.viewport.View())
	} else {
		emptyMsg := lipgloss.NewStyle().
			Faint(true).
			Align(lipgloss.Center).
			Render("Select a note to view")

		contentArea = contentBorder.
			Width(contentWidth - 4).
			Height(m.height - 4).
			Render(emptyMsg)
	}

	// Join all panes
	return lipgloss.JoinHorizontal(
		lipgloss.Top,
		sidebar,
		notesList,
		contentArea,
	)
}

func (m Model) viewStatusBar() string {
	var left, center, right string

	// Mode indicator
	switch m.mode {
	case ModeView:
		left = "VIEW"
	case ModeEdit:
		left = "EDIT"
	case ModeSearch:
		left = "SEARCH"
	case ModeSearchContent:
		left = "SEARCH CONTENT"
	}

	// Current location
	if m.currentFolder != "" {
		center = fmt.Sprintf("📁 %s", m.currentFolder)
	} else {
		center = "📄 All Notes"
	}

	// Help
	right = "? for help • q to quit"

	leftStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("0")).
		Background(lipgloss.Color("170")).
		Padding(0, 1)

	centerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("252"))

	rightStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("240"))

	statusBar := lipgloss.NewStyle().
		Width(m.width).
		Height(1).
		Background(lipgloss.Color("235")).
		Render(
			lipgloss.JoinHorizontal(
				lipgloss.Top,
				leftStyle.Render(left),
				centerStyle.Render(" "+center+" "),
				rightStyle.Render(strings.Repeat(" ", m.width-lipgloss.Width(left)-lipgloss.Width(center)-lipgloss.Width(right)-10)+right),
			),
		)

	if m.statusMessage != "" {
		statusBar = lipgloss.NewStyle().
			Width(m.width).
			Background(lipgloss.Color("235")).
			Foreground(lipgloss.Color("170")).
			Padding(0, 1).
			Render(m.statusMessage)
		m.statusMessage = ""
	}

	return statusBar
}

func (m *Model) updateSizes() {
	sidebarWidth := m.width / 5
	listWidth := m.width / 4
	contentWidth := m.width - sidebarWidth - listWidth - 8

	m.viewport.Width = contentWidth
	m.viewport.Height = m.height - 6

	m.textarea.SetWidth(contentWidth)
	m.textarea.SetHeight(m.height - 6)
}

func (m *Model) renderCurrentNote() {
	if m.currentNote == nil || m.currentNote.IsFolder {
		return
	}

	if m.renderer != nil {
		rendered, err := m.renderer.Render(m.currentNote.Content)
		if err == nil {
			m.viewport.SetContent(rendered)
		} else {
			m.viewport.SetContent(m.currentNote.Content)
		}
	} else {
		m.viewport.SetContent(m.currentNote.Content)
	}

	m.viewport.GotoTop()
}
