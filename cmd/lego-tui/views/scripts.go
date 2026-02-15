package views

import (
	"LEGOFlakes/cmd/lego-tui/styles"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type scriptSubState int

const (
	scriptSubList scriptSubState = iota
	scriptSubAction
	scriptSubCreate
	scriptSubConfirm    // Delete confirmation
	scriptSubConfirmRun // Run confirmation
	scriptSubRun
	scriptSubResult
)

type scriptResult struct {
	output string
	err    error
}

type scriptEditorFinished struct{ err error }

// ── Script list item ─────────────────────────────────────────
type scriptItem struct {
	name string
	path string
}

func (s scriptItem) Title() string       { return s.name }
func (s scriptItem) Description() string { return s.path }
func (s scriptItem) FilterValue() string { return s.name }

// ── Action item ──────────────────────────────────────────────
type actionItem struct {
	title string
	desc  string
}

func (a actionItem) Title() string       { return a.title }
func (a actionItem) Description() string { return a.desc }
func (a actionItem) FilterValue() string { return a.title }

// ── Model ────────────────────────────────────────────────────
type ScriptsModel struct {
	subState   scriptSubState
	scriptList list.Model
	actionList list.Model
	input      textinput.Model
	spinner    spinner.Model
	rootDir    string
	selected   string // Path of selected script
	output     string
	errMsg     string
	width      int
	height     int
	message    string // status message
}

func NewScriptsModel(rootDir string) ScriptsModel {
	sp := spinner.New()
	sp.Spinner = spinner.Line
	sp.Style = lipgloss.NewStyle().Foreground(styles.ColorWarning)

	emptyDelegate := list.NewDefaultDelegate()
	emptyList := list.New([]list.Item{}, emptyDelegate, 0, 0)
	emptyList.SetShowHelp(false)

	actionDelegate := list.NewDefaultDelegate()
	actionList := list.New([]list.Item{}, actionDelegate, 0, 0)
	actionList.SetShowHelp(false)
	actionList.Title = "Ações para o Script"
	actionList.Styles.Title = styles.Subtitle

	ti := textinput.New()
	ti.Placeholder = "nome-do-script.nu"
	ti.Focus()

	return ScriptsModel{
		subState:   scriptSubList,
		spinner:    sp,
		rootDir:    rootDir,
		scriptList: emptyList,
		actionList: actionList,
		input:      ti,
		width:      80,
		height:     24,
	}
}

func (m *ScriptsModel) Refresh() {
	var items []list.Item
	for _, folder := range []string{"scripts", "config"} {
		dir := filepath.Join(m.rootDir, folder)
		files, _ := filepath.Glob(filepath.Join(dir, "*.nu"))
		for _, f := range files {
			items = append(items, scriptItem{name: filepath.Base(f), path: f})
		}
	}

	delegate := list.NewDefaultDelegate()
	delegate.Styles.NormalTitle = delegate.Styles.NormalTitle.Foreground(styles.ColorText)
	delegate.Styles.NormalDesc = delegate.Styles.NormalDesc.Foreground(styles.ColorMuted)
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
		Foreground(styles.ColorSecondary).
		BorderLeftForeground(styles.ColorSecondary)
	delegate.Styles.SelectedDesc = delegate.Styles.SelectedDesc.
		Foreground(styles.ColorMuted).
		BorderLeftForeground(styles.ColorSecondary)

	l := list.New(items, delegate, m.width-4, m.height-6)
	l.Title = "Scripts Disponíveis"
	l.Styles.Title = styles.Subtitle
	l.SetFilteringEnabled(false)
	l.SetShowHelp(false)
	m.scriptList = l
}

func (m *ScriptsModel) refreshActionList() {
	actions := []list.Item{
		actionItem{title: "🚀 Executar", desc: "Rodar script com 'nu'"},
		actionItem{title: "📝 Editar", desc: "Abrir no editor"},
		actionItem{title: "🗑️  Deletar", desc: "Remover arquivo permanentemente"},
		actionItem{title: "↩️  Voltar", desc: "Retornar à lista"},
	}

	delegate := list.NewDefaultDelegate()
	delegate.Styles.NormalTitle = delegate.Styles.NormalTitle.Foreground(styles.ColorText)
	delegate.Styles.NormalDesc = delegate.Styles.NormalDesc.Foreground(styles.ColorMuted)
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
		Foreground(styles.ColorSecondary).
		BorderLeftForeground(styles.ColorSecondary)

	m.actionList = list.New(actions, delegate, m.width-4, m.height-6)
	m.actionList.Title = "Ações para: " + filepath.Base(m.selected)
	m.actionList.Styles.Title = styles.Subtitle
	m.actionList.SetShowHelp(false)
	m.actionList.SetFilteringEnabled(false)
}

func (m *ScriptsModel) openEditor(path string) tea.Cmd {
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "micro"
	}
	c := exec.Command(editor, path)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return scriptEditorFinished{err}
	})
}

func (m ScriptsModel) Init() tea.Cmd { return nil }

func (m ScriptsModel) Update(msg tea.Msg) (ScriptsModel, tea.Cmd) {

	switch msg := msg.(type) {
	case scriptEditorFinished:
		if msg.err != nil {
			m.message = "Erro no editor: " + msg.err.Error()
		}
		m.subState = scriptSubList
		return m, nil
	}

	switch m.subState {
	case scriptSubList:
		return m.updateList(msg)
	case scriptSubAction:
		return m.updateAction(msg)
	case scriptSubCreate:
		return m.updateCreate(msg)
	case scriptSubConfirm:
		return m.updateConfirm(msg)
	case scriptSubConfirmRun:
		return m.updateConfirmRun(msg)
	case scriptSubRun:
		return m.updateRun(msg)
	case scriptSubResult:
		return m.updateResult(msg)
	}
	return m, nil
}

func (m ScriptsModel) updateList(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if item, ok := m.scriptList.SelectedItem().(scriptItem); ok {
				m.selected = item.path
				m.subState = scriptSubAction
				m.refreshActionList()
			}
			return m, nil
		case "n":
			m.subState = scriptSubCreate
			m.input.SetValue("")
			m.input.Focus()
			return m, textinput.Blink
		case "d":
			if item, ok := m.scriptList.SelectedItem().(scriptItem); ok {
				m.selected = item.path
				m.subState = scriptSubConfirm
			}
			return m, nil
		case "e":
			if item, ok := m.scriptList.SelectedItem().(scriptItem); ok {
				m.selected = item.path
				return m, m.openEditor(m.selected)
			}
			return m, nil
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.scriptList.SetSize(msg.Width-4, msg.Height-6)
		m.actionList.SetSize(msg.Width-4, msg.Height-6)
	}

	var cmd tea.Cmd
	m.scriptList, cmd = m.scriptList.Update(msg)
	return m, cmd
}

func (m ScriptsModel) updateAction(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if item, ok := m.actionList.SelectedItem().(actionItem); ok {
				switch item.title {
				case "🚀 Executar":
					m.subState = scriptSubConfirmRun
					return m, nil
				case "📝 Editar":
					return m, m.openEditor(m.selected)
				case "🗑️  Deletar":
					m.subState = scriptSubConfirm
					return m, nil
				case "↩️  Voltar":
					m.subState = scriptSubList
					return m, nil
				}
			}
		case "n":
			m.subState = scriptSubCreate
			m.input.SetValue("")
			m.input.Focus()
			return m, textinput.Blink
		case "d":
			m.subState = scriptSubConfirm
			return m, nil
		case "e":
			return m, m.openEditor(m.selected)
		case "esc":
			m.subState = scriptSubList
			return m, nil
		}
	}
	var cmd tea.Cmd
	m.actionList, cmd = m.actionList.Update(msg)
	return m, cmd
}

func (m ScriptsModel) updateCreate(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			name := m.input.Value()
			if name == "" {
				return m, nil
			}
			if !strings.HasSuffix(name, ".nu") {
				name += ".nu"
			}
			path := filepath.Join(m.rootDir, "scripts", name)

			// Create file
			f, err := os.Create(path)
			if err != nil {
				m.message = "Erro ao criar: " + err.Error()
				m.subState = scriptSubList
				return m, nil
			}
			f.WriteString("#!/usr/bin/env nu\n\n\n")
			f.Close()

			m.selected = path
			m.Refresh()
			m.subState = scriptSubList
			return m, m.openEditor(path) // Open editor immediately

		case "esc":
			m.subState = scriptSubList
			return m, nil
		}
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m ScriptsModel) updateResult(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter", "esc":
			m.subState = scriptSubList
			m.output = ""
			m.errMsg = ""
			return m, nil
		}
	}
	return m, nil
}

func (m ScriptsModel) updateConfirm(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			// Delete file
			err := os.Remove(m.selected)
			if err != nil {
				m.message = "Erro ao deletar: " + err.Error()
			} else {
				m.message = "🗑️ Script deletado!"
			}
			m.Refresh()
			m.subState = scriptSubList
			return m, nil
		case "n", "N", "esc":
			m.subState = scriptSubList
			return m, nil
		}
	}
	return m, nil
}

func (m ScriptsModel) updateConfirmRun(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			m.subState = scriptSubRun
			return m, tea.Batch(m.spinner.Tick, m.runScript())
		case "n", "N", "esc":
			m.subState = scriptSubList
			return m, nil
		}
	}
	return m, nil
}

func (m ScriptsModel) updateRun(msg tea.Msg) (ScriptsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case scriptResult:
		if msg.err != nil {
			m.errMsg = msg.err.Error()
			m.output = msg.output
		} else {
			m.output = msg.output
		}
		m.subState = scriptSubResult // Always go to result
		return m, nil
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m ScriptsModel) runScript() tea.Cmd {
	return func() tea.Msg {
		path, err := exec.LookPath("nu")
		if err != nil {
			return scriptResult{err: fmt.Errorf("nu not found in PATH")}
		}

		cmd := exec.Command(path, m.selected)
		out, err := cmd.CombinedOutput()
		return scriptResult{output: string(out), err: err}
	}
}

func (m ScriptsModel) HelpKeys() string {
	switch m.subState {
	case scriptSubList:
		return "enter: sub-menu • n: novo • d: deletar • e: editar"
	case scriptSubAction:
		return "enter: selecionar ação • esc: voltar"
	case scriptSubCreate:
		return "enter: confirmar (abre editor) • esc: cancelar"
	case scriptSubConfirm:
		return "y: confirmar • n/esc: cancelar"
	case scriptSubConfirmRun:
		return "y: confirmar • n/esc: cancelar"
	case scriptSubRun:
		return "aguarde..."
	case scriptSubResult:
		return "enter/esc: voltar"
	}
	return ""
}

func (m ScriptsModel) View() string {
	var s string

	switch m.subState {
	case scriptSubList:
		title := styles.Subtitle.Render("SCRIPTS DISPONÍVEIS")
		status := ""
		if m.message != "" {
			status = "\n" + styles.MutedStyle.Render(m.message)
		}
		s = title + "\n\n" + m.scriptList.View() + status

	case scriptSubAction:
		s = m.actionList.View()

	case scriptSubCreate:
		title := styles.Subtitle.Render("NOVO SCRIPT")
		s = title + "\n\n  Nome do arquivo:\n  " + m.input.View()

	case scriptSubConfirm:
		title := styles.Subtitle.Render("CONFIRMAR DELEÇÃO")
		fname := filepath.Base(m.selected)
		warn := styles.WarningStyle.Render(fmt.Sprintf(
			"\n  ⚠️  Deletar '%s'?\n", fname))
		s = title + warn

	case scriptSubConfirmRun:
		title := styles.Subtitle.Render("CONFIRMAR EXECUÇÃO")
		fname := filepath.Base(m.selected)
		warn := styles.WarningStyle.Render(fmt.Sprintf(
			"\n  ⚠️  Executar '%s'?\n", fname))
		s = title + warn

	case scriptSubRun:
		title := styles.Subtitle.Render("EXECUTANDO")
		s = title + "\n\n  " + m.spinner.View() + " Executando " + filepath.Base(m.selected) + "..."

	case scriptSubResult:
		title := styles.Subtitle.Render("RESULTADO")
		out := m.output
		if len(out) > 800 {
			out = out[len(out)-800:]
		}
		resStyle := styles.SuccessStyle
		icon := "✅"
		if m.errMsg != "" {
			resStyle = styles.ErrorStyle
			icon = "❌"
		}

		s = title + "\n\n" +
			resStyle.Render(fmt.Sprintf("  %s Execução finalizada", icon)) + "\n"

		if m.errMsg != "" {
			s += styles.MutedStyle.Render("  Erro: "+m.errMsg) + "\n"
		}

		s += "\n" + styles.MutedStyle.Render(strings.TrimSpace(out))
	}

	return lipgloss.NewStyle().Padding(1, 2).Render(s)
}

func (m *ScriptsModel) SetSize(w, h int) {
	m.width = w
	m.height = h
	m.scriptList.SetSize(w-4, h-8)
	m.actionList.SetSize(w-4, h-6)
}
