package views

import (
	"LEGOFlakes/cmd/lego-tui/engine"
	"LEGOFlakes/cmd/lego-tui/styles"
	"fmt"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type buildState int

const (
	buildIdle buildState = iota
	buildRunning
	buildDone
	buildError
)

// ── Messages ─────────────────────────────────────────────────
type buildResult struct {
	path string
	err  error
}

// ── Model ────────────────────────────────────────────────────
type BuilderModel struct {
	state     buildState
	spinner   spinner.Model
	nameInput textinput.Model
	rootDir   string
	result    string
	errMsg    string
	width     int
	height    int
}

func NewBuilderModel(rootDir string) BuilderModel {
	sp := spinner.New()
	sp.Spinner = spinner.Dot
	sp.Style = lipgloss.NewStyle().Foreground(styles.ColorAccent)

	ti := textinput.New()
	ti.Placeholder = "(deixe vazio para timestamp automático)"
	ti.CharLimit = 40
	ti.Width = 50

	return BuilderModel{
		state:     buildIdle,
		spinner:   sp,
		nameInput: ti,
		rootDir:   rootDir,
		width:     80,
		height:    24,
	}
}

func (m BuilderModel) Init() tea.Cmd { return nil }

func (m BuilderModel) Update(msg tea.Msg) (BuilderModel, tea.Cmd) {
	switch m.state {
	case buildIdle:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "esc":
				return m, nil
			}
		}
		var cmd tea.Cmd
		m.nameInput, cmd = m.nameInput.Update(msg)
		return m, cmd

	case buildRunning:
		switch msg := msg.(type) {
		case buildResult:
			if msg.err != nil {
				m.state = buildError
				m.errMsg = msg.err.Error()
			} else {
				m.state = buildDone
				m.result = msg.path
			}
			return m, nil
		case spinner.TickMsg:
			var cmd tea.Cmd
			m.spinner, cmd = m.spinner.Update(msg)
			return m, cmd
		}

	case buildDone, buildError:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "enter", "esc":
				m.state = buildIdle
				m.result = ""
				m.errMsg = ""
				m.nameInput.SetValue("")
				return m, nil
			case "e":
				if m.state == buildDone && m.result != "" {
					return m, openEditor(m.result)
				}
			}
		case editorFinishedMsg:
			return m, nil
		}
	}

	return m, nil
}

// StartBuild kicks off the build process
func (m *BuilderModel) StartBuild(presetName, presetsDir string, modules []string) tea.Cmd {
	m.state = buildRunning
	name := m.nameInput.Value()

	return tea.Batch(m.spinner.Tick, func() tea.Msg {
		presetPath := fmt.Sprintf("%s/%s.toml", presetsDir, presetName)
		preset, err := engine.LoadPreset(presetPath)
		if err != nil {
			return buildResult{err: err}
		}
		path, err := engine.BuildFlake(m.rootDir, preset, modules, name)
		if err != nil {
			return buildResult{err: err}
		}
		// Update preset file
		engine.SavePreset(presetPath, preset)
		return buildResult{path: path}
	})
}

func (m BuilderModel) HelpKeys() string {
	switch m.state {
	case buildIdle:
		return "enter: gerar com o preset selecionado"
	case buildDone:
		return "e: abrir no editor • esc: voltar"
	case buildError:
		return "enter: voltar"
	case buildRunning:
		return "aguarde..."
	}
	return ""
}

func (m BuilderModel) View() string {
	var s string
	title := styles.Subtitle.Render("GERAR FLAKE")

	switch m.state {
	case buildIdle:
		label := styles.NormalItem.Render("\n  Nome personalizado para a flake:")
		s = title + label + "\n\n  " + m.nameInput.View()
	case buildRunning:
		s = title + "\n\n  " + m.spinner.View() + " Gerando flake..."
	case buildDone:
		s = title + "\n\n" +
			styles.SuccessStyle.Render("  ✅ Flake gerada com sucesso!") + "\n\n" +
			styles.NormalItem.Render("  Arquivo: "+m.result)
	case buildError:
		s = title + "\n\n" +
			styles.ErrorStyle.Render("  ❌ Erro na geração:") + "\n" +
			styles.MutedStyle.Render("  "+m.errMsg)
	}

	return lipgloss.NewStyle().Padding(1, 2).Render(s)
}

func (m *BuilderModel) SetSize(w, h int) {
	m.width = w
	m.height = h
}

func (m *BuilderModel) FocusInput() tea.Cmd {
	m.nameInput.Focus()
	return m.nameInput.Cursor.BlinkCmd()
}
