package views

import (
	"LEGOFlakes/cmd/lego-tui/engine"
	"LEGOFlakes/cmd/lego-tui/styles"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/spinner"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type installState int

const (
	installIdle installState = iota
	installConfirm
	installRunning
	installDone
	installError
)

type installResult struct {
	output string
	err    error
}

type installerEditorFinished struct{ err error }

// ── Flake list item ──────────────────────────────────────────
type flakeItem struct {
	name string
	path string
}

func (f flakeItem) Title() string       { return f.name }
func (f flakeItem) Description() string { return f.path }
func (f flakeItem) FilterValue() string { return f.name }

// ── Model ────────────────────────────────────────────────────
type InstallerModel struct {
	state     installState
	flakeList list.Model
	spinner   spinner.Model
	rootDir   string
	selected  string
	hostname  string
	output    string
	errMsg    string
	width     int
	height    int
}

func NewInstallerModel(rootDir string) InstallerModel {
	sp := spinner.New()
	sp.Spinner = spinner.Line
	sp.Style = lipgloss.NewStyle().Foreground(styles.ColorWarning)

	// Initialize an empty flake list to avoid nil pointer on SetSize
	emptyDelegate := list.NewDefaultDelegate()
	emptyFlakeList := list.New([]list.Item{}, emptyDelegate, 76, 14)
	emptyFlakeList.SetShowHelp(false)

	return InstallerModel{
		state:     installIdle,
		spinner:   sp,
		rootDir:   rootDir,
		flakeList: emptyFlakeList,
		width:     80,
		height:    24,
	}
}

func (m *InstallerModel) RefreshFlakes(presetName string) {
	var items []list.Item
	dir := filepath.Join(m.rootDir, "flakes")
	files, _ := filepath.Glob(filepath.Join(dir, "*.nix"))
	for _, f := range files {
		name := filepath.Base(f)
		if presetName == "" || strings.HasPrefix(name, presetName) {
			items = append(items, flakeItem{name: name, path: f})
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
	l.Title = "Flakes geradas"
	l.Styles.Title = styles.Subtitle
	l.SetFilteringEnabled(false)
	l.SetShowHelp(false)
	m.flakeList = l
	m.hostname = presetName
}

func (m *InstallerModel) openEditor(path string) tea.Cmd {
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "micro"
	}
	c := exec.Command(editor, path)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return installerEditorFinished{err}
	})
}

func (m InstallerModel) Init() tea.Cmd { return nil }

func (m InstallerModel) Update(msg tea.Msg) (InstallerModel, tea.Cmd) {
	switch msg := msg.(type) {
	case installerEditorFinished:
		if msg.err != nil {
			m.state = installError
			m.errMsg = "Erro no editor: " + msg.err.Error()
		}
		return m, nil
	}

	switch m.state {
	case installIdle:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "enter":
				if item, ok := m.flakeList.SelectedItem().(flakeItem); ok {
					m.selected = item.path
					m.state = installConfirm
					return m, nil
				}
			case "e":
				if item, ok := m.flakeList.SelectedItem().(flakeItem); ok {
					return m, m.openEditor(item.path)
				}
			}
		case tea.WindowSizeMsg:
			m.width = msg.Width
			m.height = msg.Height
			m.flakeList.SetSize(msg.Width-4, msg.Height-10)
		}
		var cmd tea.Cmd
		m.flakeList, cmd = m.flakeList.Update(msg)
		return m, cmd

	case installConfirm:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "y", "Y":
				m.state = installRunning
				return m, tea.Batch(m.spinner.Tick, m.runRebuild())
			case "n", "N", "esc":
				m.state = installIdle
				return m, nil
			}
		}

	case installRunning:
		switch msg := msg.(type) {
		case installResult:
			if msg.err != nil {
				m.state = installError
				m.errMsg = msg.err.Error()
				m.output = msg.output
			} else {
				m.state = installDone
				m.output = msg.output
			}
			return m, nil
		case spinner.TickMsg:
			var cmd tea.Cmd
			m.spinner, cmd = m.spinner.Update(msg)
			return m, cmd
		}

	case installDone, installError:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "enter", "esc":
				m.state = installIdle
				m.output = ""
				m.errMsg = ""
				return m, nil
			}
		}
	}

	return m, nil
}

func (m InstallerModel) runRebuild() tea.Cmd {
	return func() tea.Msg {
		flakeDir := filepath.Dir(m.selected)
		out, err := engine.NixosRebuild(flakeDir, m.hostname)
		return installResult{output: out, err: err}
	}
}

func (m InstallerModel) HelpKeys() string {
	switch m.state {
	case installIdle:
		return "enter: selecionar flake para aplicar • e: editar"
	case installConfirm:
		return "y: confirmar • n/esc: cancelar"
	case installRunning:
		return "aguarde..."
	case installDone, installError:
		return "enter: voltar"
	}
	return ""
}

func (m InstallerModel) View() string {
	var s string
	title := styles.Subtitle.Render("APLICAR FLAKE")

	switch m.state {
	case installIdle:
		s = title + "\n\n" + m.flakeList.View()
	case installConfirm:
		fname := filepath.Base(m.selected)
		warn := styles.WarningStyle.Render(fmt.Sprintf(
			"\n  ⚠️  Aplicar '%s' no sistema?\n  Isso irá executar nixos-rebuild switch.\n", fname))
		s = title + warn
	case installRunning:
		s = title + "\n\n  " + m.spinner.View() + " Executando nixos-rebuild switch..."
	case installDone:
		out := m.output
		if len(out) > 500 {
			out = out[len(out)-500:]
		}
		s = title + "\n\n" +
			styles.SuccessStyle.Render("  ✅ Configuração aplicada com sucesso!") + "\n\n" +
			styles.MutedStyle.Render(out)
	case installError:
		out := m.output
		if len(out) > 500 {
			out = out[len(out)-500:]
		}
		s = title + "\n\n" +
			styles.ErrorStyle.Render("  ❌ Erro ao aplicar:") + "\n" +
			styles.MutedStyle.Render("  "+m.errMsg) + "\n\n" +
			styles.MutedStyle.Render(out)
	}

	return lipgloss.NewStyle().Padding(1, 2).Render(s)
}

func (m *InstallerModel) SetSize(w, h int) {
	m.width = w
	m.height = h
	m.flakeList.SetSize(w-4, h-6)
}
