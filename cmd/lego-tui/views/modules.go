package views

import (
	"LEGOFlakes/cmd/lego-tui/engine"
	"LEGOFlakes/cmd/lego-tui/styles"
	"fmt"
	"io"
	"os"
	"os/exec"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ── Sub-states ───────────────────────────────────────────────
type moduleSubState int

const (
	moduleSubList moduleSubState = iota
	moduleSubCreate
	moduleSubConfirmDelete
)

// ── Module list item ─────────────────────────────────────────
type moduleItem struct {
	info engine.ModuleInfo
}

func (m moduleItem) Title() string {
	title := fmt.Sprintf("[%s] %s", m.info.Category, m.info.Name)
	if m.info.Purpose != "" {
		title += " — " + m.info.Purpose
	}
	return title
}
func (m moduleItem) Description() string { return "" }
func (m moduleItem) FilterValue() string { return m.info.Name + " " + m.info.Category }

// ── Category item ────────────────────────────────────────────
type categoryItem struct {
	cat  string
	desc string
}

func (c categoryItem) Title() string       { return c.cat }
func (c categoryItem) Description() string { return c.desc }
func (c categoryItem) FilterValue() string { return c.cat }

// ── Create form step ─────────────────────────────────────────
type createStep int

const (
	createStepCategory createStep = iota
	createStepName
)

// ── Custom module delegate for compact list ──────────────────

type compactDelegate struct{}

func (d compactDelegate) Height() int                             { return 1 }
func (d compactDelegate) Spacing() int                            { return 0 }
func (d compactDelegate) Update(_ tea.Msg, _ *list.Model) tea.Cmd { return nil }
func (d compactDelegate) Render(w io.Writer, m list.Model, index int, item list.Item) {
	i, ok := item.(moduleItem)
	if !ok {
		return
	}

	title := fmt.Sprintf("[%s] %s", i.info.Category, i.info.Name)
	if i.info.Purpose != "" {
		title += " — " + i.info.Purpose
	}

	// Estilização
	var style lipgloss.Style
	if index == m.Index() {
		style = lipgloss.NewStyle().
			Foreground(styles.ColorSecondary).
			BorderLeft(true).
			BorderStyle(lipgloss.NormalBorder()).
			BorderLeftForeground(styles.ColorSecondary).
			PaddingLeft(1)
	} else {
		style = styles.NormalItem.Copy().PaddingLeft(2)
	}

	fmt.Fprint(w, style.Render(title))
}

// ── Model ────────────────────────────────────────────────────
type ModulesModel struct {
	list           list.Model
	catList        list.Model
	nameInput      textinput.Model
	subState       moduleSubState
	createStep     createStep
	rootDir        string
	newCategory    string
	message        string
	width          int
	height         int
	selectedModule moduleItem
}

func NewModulesModel(rootDir string) ModulesModel {
	ti := textinput.New()
	ti.Placeholder = "meu-modulo"
	ti.CharLimit = 80
	ti.Width = 80

	m := ModulesModel{
		rootDir:   rootDir,
		nameInput: ti,
		subState:  moduleSubList,
		width:     80,
		height:    24,
	}
	m.refreshList()
	m.buildCatList()
	return m
}

func (m *ModulesModel) refreshList() {
	mods := engine.ListModules(m.rootDir)
	items := make([]list.Item, len(mods))
	for i, mod := range mods {
		items[i] = moduleItem{info: mod}
	}

	// ✨ USA O DELEGATE CUSTOMIZADO ✨
	l := list.New(items, compactDelegate{}, m.width-4, m.height-8)
	l.Title = "Módulos disponíveis"
	l.Styles.Title = styles.Subtitle
	l.SetFilteringEnabled(true)
	l.SetShowHelp(false)
	l.SetShowStatusBar(false)
	m.list = l
}

func (m *ModulesModel) buildCatList() {
	items := make([]list.Item, len(engine.Categories))
	for i, c := range engine.Categories {
		items[i] = categoryItem{
			cat:  c,
			desc: engine.CategoryDescriptions[c],
		}
	}
	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
		Foreground(styles.ColorSecondary).
		BorderLeftForeground(styles.ColorSecondary)

	l := list.New(items, delegate, m.width-4, 12)
	l.Title = "Selecione a categoria"
	l.Styles.Title = styles.Subtitle
	l.SetFilteringEnabled(false)
	l.SetShowHelp(false)
	m.catList = l
}

func (m ModulesModel) Init() tea.Cmd { return nil }

func (m ModulesModel) Update(msg tea.Msg) (ModulesModel, tea.Cmd) {
	switch m.subState {
	case moduleSubList:
		return m.updateList(msg)
	case moduleSubCreate:
		return m.updateCreate(msg)
	case moduleSubConfirmDelete:
		return m.updateConfirmDelete(msg)
	}
	return m, nil
}

func (m ModulesModel) updateList(msg tea.Msg) (ModulesModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "n":
			if !m.list.SettingFilter() {
				m.subState = moduleSubCreate
				m.createStep = createStepCategory
				m.message = ""
				return m, nil
			}
		case "d": // Delete handler
			if !m.list.SettingFilter() {
				if item, ok := m.list.SelectedItem().(moduleItem); ok {
					m.selectedModule = item
					m.subState = moduleSubConfirmDelete
					m.message = ""
					return m, nil
				}
			}

		case "e":
			if !m.list.SettingFilter() {
				if item, ok := m.list.SelectedItem().(moduleItem); ok {
					return m, openEditor(item.info.FullPath)
				}
			}
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.list.SetSize(msg.Width-4, msg.Height-12)
	case editorFinishedMsg:
		m.refreshList()
		return m, nil
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m ModulesModel) updateCreate(msg tea.Msg) (ModulesModel, tea.Cmd) {
	switch m.createStep {
	case createStepCategory:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "esc":
				m.subState = moduleSubList
				return m, nil
			case "enter":
				if item, ok := m.catList.SelectedItem().(categoryItem); ok {
					m.newCategory = item.cat
					m.createStep = createStepName
					m.nameInput.Focus()
					return m, m.nameInput.Cursor.BlinkCmd()
				}
			}
		}
		var cmd tea.Cmd
		m.catList, cmd = m.catList.Update(msg)
		return m, cmd

	case createStepName:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "esc":
				m.createStep = createStepCategory
				m.nameInput.SetValue("")
				return m, nil
			case "enter":
				name := m.nameInput.Value()
				if name == "" {
					m.message = "Nome não pode ser vazio"
					return m, nil
				}
				// Create module file with LEGO header
				path := fmt.Sprintf("%s/modules/%s/%s.nix", m.rootDir, m.newCategory, name)
				content := fmt.Sprintf(`# NIXOS-LEGO-MODULE: %s
# PURPOSE: <descreva o propósito>
# CATEGORY: %s
# AUTHOR: user
`, name, m.newCategory)
				if err := os.WriteFile(path, []byte(content), 0644); err != nil {
					m.message = "Erro: " + err.Error()
					return m, nil
				}
				m.nameInput.SetValue("")
				m.subState = moduleSubList
				m.refreshList()
				// Open editor for the new module
				return m, openEditor(path)
			}
		}
		var cmd tea.Cmd
		m.nameInput, cmd = m.nameInput.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m ModulesModel) updateConfirmDelete(msg tea.Msg) (ModulesModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y", "enter":
			path := m.selectedModule.info.FullPath
			if err := os.Remove(path); err != nil {
				m.message = "Erro ao deletar: " + err.Error()
			} else {
				m.message = fmt.Sprintf("🗑️ Módulo '%s' deletado!", m.selectedModule.Title())
			}
			m.subState = moduleSubList
			m.refreshList()
			return m, nil
		case "n", "N", "esc":
			m.message = "Operação cancelada."
			m.subState = moduleSubList
			return m, nil
		}
	}
	return m, nil
}

func (m ModulesModel) HelpKeys() string {
	switch m.subState {
	case moduleSubList:
		return "n: novo módulo • e: editar • d: deletar • /: filtrar"
	case moduleSubCreate:
		switch m.createStep {
		case createStepCategory:
			return "enter: selecionar • esc: cancelar"
		case createStepName:
			return "enter: criar • esc: voltar"
		}
	case moduleSubConfirmDelete:
		return "y/enter: confirmar • n/esc: cancelar"
	}
	return ""
}

func (m ModulesModel) View() string {
	var s string
	switch m.subState {
	case moduleSubList:
		header := ""
		if m.message != "" {
			header = styles.SuccessStyle.Render(m.message) + "\n\n"
		}
		s = header + m.list.View()
	case moduleSubCreate:
		switch m.createStep {
		case createStepCategory:
			s = m.catList.View()
		case createStepName:
			title := styles.Subtitle.Render(fmt.Sprintf("NOVO MÓDULO [%s]", m.newCategory))
			label := styles.NormalItem.Render("\n  Nome do módulo (kebab-case):\n")
			errMsg := ""
			if m.message != "" {
				errMsg = "\n" + styles.ErrorStyle.Render("  "+m.message)
			}
			s = title + label + "\n  " + m.nameInput.View() + errMsg
		}
	case moduleSubConfirmDelete:
		title := styles.Subtitle.Render("CONFIRMAR DELEÇÃO")
		dialog := fmt.Sprintf("\n  Tem certeza que deseja deletar o módulo:\n  %s?\n\n", styles.ErrorStyle.Render(m.selectedModule.Title()))
		s = title + dialog
	}
	return lipgloss.NewStyle().Padding(1, 2).Render(s)
}

func (m *ModulesModel) SetSize(w, h int) {
	m.width = w
	m.height = h
	m.list.SetSize(w-6, h-6)
	m.catList.SetSize(w-6, h-6)
}

// ── Shared helpers ───────────────────────────────────────────
type editorFinishedMsg struct{}

func openEditor(path string) tea.Cmd {
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "micro"
	}
	c := exec.Command(editor, path)
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return editorFinishedMsg{}
	})
}

func removeFile(path string) error {
	return os.Remove(path)
}
