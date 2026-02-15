package views

import (
	"LEGOFlakes/cmd/lego-tui/engine"
	"LEGOFlakes/cmd/lego-tui/styles"
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ── Selection Model ──────────────────────────────────────────
type SelectionModel struct {
	modules  []engine.ModuleInfo
	selected map[string]bool
	cursor   int
	rootDir  string
	message  string
	width    int
	height   int
}

func NewSelectionModel(rootDir string) SelectionModel {
	mods := engine.ListModules(rootDir)
	return SelectionModel{
		modules:  mods,
		selected: make(map[string]bool),
		rootDir:  rootDir,
		width:    80,
		height:   24,
	}
}

func (m SelectionModel) Init() tea.Cmd { return nil }

func (m SelectionModel) Update(msg tea.Msg) (SelectionModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "up", "k":
			if m.cursor > 0 {
				m.cursor--
			}
		case "down", "j":
			if m.cursor < len(m.modules)-1 {
				m.cursor++
			}
		case " ":
			if len(m.modules) > 0 {
				key := m.modules[m.cursor].RelPath
				m.selected[key] = !m.selected[key]
			}
		case "a":
			allSelected := true
			for _, mod := range m.modules {
				if !m.selected[mod.RelPath] {
					allSelected = false
					break
				}
			}
			for _, mod := range m.modules {
				m.selected[mod.RelPath] = !allSelected
			}
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}
	return m, nil
}

func (m SelectionModel) HelpKeys() string {
	return "space: toggle • a: todos • j/k: navegar"
}

func (m SelectionModel) View() string {
	title := styles.Subtitle.Render("SELECIONAR MÓDULOS")
	count := 0
	for _, v := range m.selected {
		if v {
			count++
		}
	}
	counter := styles.MutedStyle.Render(fmt.Sprintf("  %d selecionado(s)", count))

	lines := ""
	scrollStart := 0
	maxVisible := m.height - 10
	if maxVisible < 5 {
		maxVisible = 5
	}
	if m.cursor >= scrollStart+maxVisible {
		scrollStart = m.cursor - maxVisible + 1
	}

	for i, mod := range m.modules {
		if i < scrollStart || i >= scrollStart+maxVisible {
			continue
		}
		cursor := "  "
		if i == m.cursor {
			cursor = "▸ "
		}

		check := "[ ]"
		if m.selected[mod.RelPath] {
			check = "[✓]"
		}

		label := fmt.Sprintf("[%s] %s", mod.Category, mod.Name)
		if mod.Purpose != "" {
			label += " — " + mod.Purpose
		}

		style := styles.NormalItem
		if i == m.cursor {
			style = styles.SelectedItem
		}

		checkStyle := styles.MutedStyle
		if m.selected[mod.RelPath] {
			checkStyle = lipgloss.NewStyle().Foreground(styles.ColorSecondary)
		}

		lines += cursor + checkStyle.Render(check) + " " + style.Render(label) + "\n"
	}

	return lipgloss.NewStyle().Padding(1, 2).Render(
		title + "\n" + counter + "\n\n" + lines)
}

func (m *SelectionModel) SetSize(w, h int) {
	m.width = w
	m.height = h
}

// GetSelected returns the list of selected module relative paths
func (m SelectionModel) GetSelected() []string {
	var result []string
	for k, v := range m.selected {
		if v {
			result = append(result, k)
		}
	}
	return result
}

// Refresh reloads the module list
func (m *SelectionModel) Refresh() {
	m.modules = engine.ListModules(m.rootDir)
}
