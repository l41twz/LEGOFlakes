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
	buildMenu buildState = iota // starts here: pick action
	buildName                   // typing flake name
	buildRunning
	buildDone
	buildError
	buildSaved
)

// ── Messages ─────────────────────────────────────────────────
type buildResult struct {
	path string
	err  error
}

type saveResult struct {
	presetName string
	err        error
}

// ── Model ────────────────────────────────────────────────────
type BuilderModel struct {
	state      buildState
	spinner    spinner.Model
	nameInput  textinput.Model
	rootDir    string
	result     string
	errMsg     string
	menuCursor int
	width      int
	height     int
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
		state:     buildMenu,
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
	case buildMenu:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "up", "k":
				if m.menuCursor > 0 {
					m.menuCursor--
				}
			case "down", "j":
				if m.menuCursor < 1 {
					m.menuCursor++
				}
			case "esc":
				return m, nil
			}
		}
		return m, nil

	case buildName:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "esc":
				m.state = buildMenu
				m.nameInput.SetValue("")
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
		case saveResult:
			if msg.err != nil {
				m.state = buildError
				m.errMsg = msg.err.Error()
			} else {
				m.state = buildSaved
				m.result = msg.presetName
			}
			return m, nil
		case spinner.TickMsg:
			var cmd tea.Cmd
			m.spinner, cmd = m.spinner.Update(msg)
			return m, cmd
		}

	case buildDone, buildError, buildSaved:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "enter", "esc":
				m.state = buildMenu
				m.result = ""
				m.errMsg = ""
				m.menuCursor = 0
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

// SavePresetOnly saves the selected modules to the preset without generating a flake
func (m *BuilderModel) SavePresetOnly(presetName, presetsDir string, modules []string) tea.Cmd {
	m.state = buildRunning

	return tea.Batch(m.spinner.Tick, func() tea.Msg {
		presetPath := fmt.Sprintf("%s/%s.toml", presetsDir, presetName)
		preset, err := engine.LoadPreset(presetPath)
		if err != nil {
			return saveResult{err: err}
		}
		preset.Modules.Active = modules
		if err := engine.SavePreset(presetPath, preset); err != nil {
			return saveResult{err: err}
		}
		return saveResult{presetName: presetName}
	})
}

// GoToNameInput transitions from menu to name input state
func (m *BuilderModel) GoToNameInput() tea.Cmd {
	m.state = buildName
	m.nameInput.Focus()
	return m.nameInput.Cursor.BlinkCmd()
}

// MenuCursor returns the current menu selection (0=build, 1=save)
func (m BuilderModel) MenuCursor() int {
	return m.menuCursor
}

// IsMenu returns whether the builder is in menu state
func (m BuilderModel) IsMenu() bool {
	return m.state == buildMenu
}

// IsNameInput returns whether the builder is in name input state
func (m BuilderModel) IsNameInput() bool {
	return m.state == buildName
}

func (m BuilderModel) HelpKeys() string {
	switch m.state {
	case buildMenu:
		return "enter: confirmar • j/k: navegar"
	case buildName:
		return "enter: gerar flake • esc: voltar"
	case buildDone:
		return "e: abrir no editor • esc: voltar"
	case buildSaved:
		return "enter/esc: voltar"
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
	case buildMenu:
		options := []struct {
			title string
			desc  string
		}{
			{"🔨 Gerar Flake", "Gera o flake.nix e salva os módulos no preset"},
			{"💾 Salvar Preset", "Salva os módulos selecionados no preset (sem gerar flake)"},
		}
		lines := "\n"
		for i, opt := range options {
			cursor := "  "
			style := styles.NormalItem
			if i == m.menuCursor {
				cursor = "▸ "
				style = lipgloss.NewStyle().Foreground(styles.ColorSecondary)
			}
			lines += cursor + style.Render(opt.title) + "\n"
			lines += "    " + styles.MutedStyle.Render(opt.desc) + "\n\n"
		}
		s = title + lines
	case buildName:
		label := styles.NormalItem.Render("\n  Nome personalizado para a flake:")
		hint := styles.MutedStyle.Render("\n  (deixe vazio e pressione enter para usar host+timestamp)")
		s = title + label + "\n\n  " + m.nameInput.View() + hint
	case buildRunning:
		s = title + "\n\n  " + m.spinner.View() + " Processando..."
	case buildDone:
		s = title + "\n\n" +
			styles.SuccessStyle.Render("  ✅ Flake gerada com sucesso!") + "\n\n" +
			styles.NormalItem.Render("  Arquivo: "+m.result)
	case buildSaved:
		s = title + "\n\n" +
			styles.SuccessStyle.Render("  💾 Preset atualizado com sucesso!") + "\n\n" +
			styles.NormalItem.Render("  Preset: "+m.result)
	case buildError:
		s = title + "\n\n" +
			styles.ErrorStyle.Render("  ❌ Erro na operação:") + "\n" +
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
