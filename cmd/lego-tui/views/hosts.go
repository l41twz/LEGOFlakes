package views

import (
	"LEGOFlakes/cmd/lego-tui/engine"
	"LEGOFlakes/cmd/lego-tui/styles"
	"fmt"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ── List item adapter ────────────────────────────────────────
type presetItem struct {
	info     engine.PresetInfo
	isActive bool
}

func (p presetItem) Title() string {
	prefix := "[ ] "
	if p.isActive {
		prefix := "[✓] "
		_ = prefix
	}
	return prefix + p.info.Name
}
func (p presetItem) Description() string {
	return "modificado: " + p.info.Modified.Format("2006-01-02 15:04")
}
func (p presetItem) FilterValue() string { return p.info.Name }

// ── Sub-state ────────────────────────────────────────────
type hostSubState int

const (
	hostSubList hostSubState = iota
	hostSubCreate
	hostSubAction
)

// ── Hosts Model ──────────────────────────────────────────
type HostsModel struct {
	list         list.Model
	input        textinput.Model
	subState     hostSubState
	presetsDir   string
	rootDir      string
	selected     string
	activePreset string // Track the active preset
	actionList   list.Model
	message      string
	err          error
	width        int
	height       int
}

func NewHostsModel(presetsDir, rootDir string) HostsModel {
	// Text input for new preset
	ti := textinput.New()
	ti.Placeholder = "meu-desktop"
	ti.CharLimit = 32
	ti.Width = 40

	// Initialize an empty action list to avoid nil pointer on SetSize
	emptyDelegate := list.NewDefaultDelegate()
	emptyActionList := list.New([]list.Item{}, emptyDelegate, 80, 18)
	emptyActionList.SetShowHelp(false)

	m := HostsModel{
		presetsDir: presetsDir,
		rootDir:    rootDir,
		input:      ti,
		subState:   hostSubList,
		width:      80,
		height:     24,
		actionList: emptyActionList,
	}
	m.refreshList()
	return m
}

func (m *HostsModel) refreshList() {
	presets, _ := engine.ListPresets(m.presetsDir)
	items := make([]list.Item, len(presets))
	for i, p := range presets {
		items[i] = presetItem{
			info:     p,
			isActive: m.activePreset == p.Name,
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

	l := list.New(items, delegate, m.width, m.height-6)
	l.Title = "Presets disponíveis"
	l.Styles.Title = styles.Subtitle
	l.SetShowStatusBar(true)
	l.SetFilteringEnabled(true)
	l.SetShowHelp(false)
	m.list = l
}

func (m *HostsModel) refreshActionList() {
	actions := []list.Item{
		simpleItem{title: "✅ Escolher Preset", desc: "Definir como ativo para build"},
		simpleItem{title: "📝 Editar Preset", desc: "Abrir no editor"},
		simpleItem{title: "🗑️  Deletar Preset", desc: "Remover permanentemente"},
		simpleItem{title: "↩️  Voltar", desc: "Retornar à lista"},
	}
	delegate := list.NewDefaultDelegate()
	delegate.Styles.SelectedTitle = delegate.Styles.SelectedTitle.
		Foreground(styles.ColorSecondary).
		BorderLeftForeground(styles.ColorSecondary)
	l := list.New(actions, delegate, m.width, m.height-6)
	l.Title = fmt.Sprintf("Preset: %s", m.selected)
	l.Styles.Title = styles.Subtitle
	l.SetShowHelp(false)
	l.SetFilteringEnabled(false)
	m.actionList = l
}

type simpleItem struct {
	title string
	desc  string
}

func (s simpleItem) Title() string       { return s.title }
func (s simpleItem) Description() string { return s.desc }
func (s simpleItem) FilterValue() string { return s.title }

func (m HostsModel) Init() tea.Cmd { return nil }

func (m HostsModel) Update(msg tea.Msg) (HostsModel, tea.Cmd) {
	switch m.subState {
	case hostSubList:
		return m.updateList(msg)
	case hostSubCreate:
		return m.updateCreate(msg)
	case hostSubAction:
		return m.updateAction(msg)
	}
	return m, nil
}

func (m HostsModel) updateList(msg tea.Msg) (HostsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "n":
			if !m.list.SettingFilter() {
				m.subState = hostSubCreate
				m.input.Focus()
				m.message = ""
				return m, m.input.Cursor.BlinkCmd()
			}
		case "enter":
			if !m.list.SettingFilter() {
				if item, ok := m.list.SelectedItem().(presetItem); ok {
					m.selected = item.info.Name
					m.subState = hostSubAction
					m.refreshActionList()
					return m, nil
				}
			}
		}
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.list.SetSize(msg.Width, msg.Height-6)
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m HostsModel) updateCreate(msg tea.Msg) (HostsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			name := m.input.Value()
			if name == "" {
				m.message = "Nome não pode ser vazio"
				return m, nil
			}
			preset := engine.NewDefaultPreset(name, "user")
			path := fmt.Sprintf("%s/%s.toml", m.presetsDir, name)
			if err := engine.SavePreset(path, preset); err != nil {
				m.err = err
				m.message = "Erro ao salvar: " + err.Error()
				return m, nil
			}
			m.message = fmt.Sprintf("✅ Preset '%s' criado!", name)
			m.input.SetValue("")
			m.subState = hostSubList
			m.refreshList()
			return m, nil
		case "esc":
			m.input.SetValue("")
			m.subState = hostSubList
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m HostsModel) updateAction(msg tea.Msg) (HostsModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "esc":
			m.subState = hostSubList
			return m, nil
		case "enter":
			if item, ok := m.actionList.SelectedItem().(simpleItem); ok {
				switch item.title {
				case "✅ Escolher Preset":
					m.activePreset = m.selected
					m.message = fmt.Sprintf("Preset '%s' selecionado!", m.selected)
					m.subState = hostSubList
					m.refreshList()
					return m, nil
				case "🗑️  Deletar Preset":
					path := fmt.Sprintf("%s/%s.toml", m.presetsDir, m.selected)
					if err := deletePresetFile(path); err != nil {
						m.message = "Erro: " + err.Error()
					} else {
						m.message = fmt.Sprintf("🗑️ Preset '%s' deletado", m.selected)
					}
					m.subState = hostSubList
					m.refreshList()
					return m, nil
				case "📝 Editar Preset":
					path := fmt.Sprintf("%s/%s.toml", m.presetsDir, m.selected)
					return m, openEditor(path)
				case "↩️  Voltar":
					m.subState = hostSubList
					return m, nil
				}
			}
		}
	}

	var cmd tea.Cmd
	m.actionList, cmd = m.actionList.Update(msg)
	return m, cmd
}

func deletePresetFile(path string) error {
	return removeFile(path)
}

func (m HostsModel) HelpKeys() string {
	switch m.subState {
	case hostSubList:
		return "n: novo preset • enter: selecionar • /: filtrar"
	case hostSubCreate:
		return "enter: confirmar • esc: cancelar"
	case hostSubAction:
		return "enter: selecionar ação • esc: voltar"
	}
	return ""
}

func (m HostsModel) View() string {
	var s string
	switch m.subState {
	case hostSubList:
		header := ""
		if m.message != "" {
			header = styles.SuccessStyle.Render(m.message) + "\n\n"
		}
		s = header + m.list.View()
	case hostSubCreate:
		title := styles.Subtitle.Render("CRIAR NOVO PRESET")
		label := styles.NormalItem.Render("\n  Nome do Preset (será usado como hostname):\n")
		errMsg := ""
		if m.message != "" {
			errMsg = "\n" + styles.ErrorStyle.Render("  "+m.message)
		}
		s = title + label + "\n  " + m.input.View() + errMsg
	case hostSubAction:
		s = m.actionList.View()
	}
	return lipgloss.NewStyle().Padding(1, 2).Render(s)
}

func (m *HostsModel) SetSize(w, h int) {
	m.width = w
	m.height = h
	m.list.SetSize(w-4, h-6)
	m.actionList.SetSize(w-4, h-6)
}

// SelectedPreset returns the currently selected preset name (for tab switching)
func (m HostsModel) SelectedPreset() string {
	return m.activePreset
}

// SelectedHostName returns the host_name from the active preset's TOML.
// This is the key used in nixosConfigurations.<hostname>.
func (m HostsModel) SelectedHostName() string {
	if m.activePreset == "" {
		return ""
	}
	path := fmt.Sprintf("%s/%s.toml", m.presetsDir, m.activePreset)
	p, err := engine.LoadPreset(path)
	if err != nil {
		return m.activePreset // fallback to filename
	}
	if p.Host.HostName != "" {
		return p.Host.HostName
	}
	return m.activePreset
}
