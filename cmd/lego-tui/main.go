package main

import (
	"LEGOFlakes/cmd/lego-tui/styles"
	"LEGOFlakes/cmd/lego-tui/views"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Tab indices
const (
	tabIntro     = 0
	tabHosts     = 1
	tabModules   = 2
	tabSelection = 3
	tabBuilder   = 4
	tabInstaller = 5
	tabScripts   = 6
	tabDisko     = 7
)

var tabNames = []string{
	"Início",
	"Hosts",
	"Módulos",
	"Seleção",
	"Gerar",
	"Aplicar",
	"Scripts",
	"Disko",
}

type model struct {
	activeTab  int
	rootDir    string
	presetsDir string

	// Sub-models
	hosts     views.HostsModel
	modules   views.ModulesModel
	selection views.SelectionModel
	builder   views.BuilderModel
	installer views.InstallerModel
	scripts   views.ScriptsModel
	disko     views.DiskoModel

	width  int
	height int
}

func initialModel() model {
	// Resolve project root: binary location or cwd-based
	root := findRoot()
	presetsDir := filepath.Join(root, "presets")

	// Ensure dirs exist
	os.MkdirAll(presetsDir, 0755)
	os.MkdirAll(filepath.Join(root, "flakes"), 0755)
	os.MkdirAll(filepath.Join(root, "scripts"), 0755)

	return model{
		activeTab:  tabIntro,
		rootDir:    root,
		presetsDir: presetsDir,
		hosts:      views.NewHostsModel(presetsDir, root),
		modules:    views.NewModulesModel(root),
		selection:  views.NewSelectionModel(root),
		builder:    views.NewBuilderModel(root),
		installer:  views.NewInstallerModel(root),
		scripts:    views.NewScriptsModel(root),
		disko:      views.NewDiskoModel(root),
		width:      120,
		height:     30,
	}
}

func findRoot() string {
	// Try env override first
	if r := os.Getenv("LEGO_ROOT"); r != "" {
		return r
	}
	// Walk up from executable
	exe, err := os.Executable()
	if err == nil {
		dir := filepath.Dir(exe)
		for dir != "/" {
			if _, err := os.Stat(filepath.Join(dir, "presets")); err == nil {
				return dir
			}
			dir = filepath.Dir(dir)
		}
	}
	// Fall back to cwd
	// Fall back to walking up from CWD
	cwd, _ := os.Getwd()
	dir := cwd
	for dir != "/" {
		if _, err := os.Stat(filepath.Join(dir, "presets")); err == nil {
			return dir
		}
		dir = filepath.Dir(dir)
	}
	return cwd
}

func (m model) Init() tea.Cmd {
	return tea.SetWindowTitle("🧱 NixOS LEGO System Builder")
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		// Reserve: tabBar ~3 lines, helpBar ~4 lines (border+padding), gap 1
		contentH := msg.Height - 8
		m.hosts.SetSize(msg.Width, contentH)
		m.modules.SetSize(msg.Width, contentH)
		m.selection.SetSize(msg.Width, contentH)
		m.builder.SetSize(msg.Width, contentH)
		m.installer.SetSize(msg.Width, contentH)
		m.disko.SetSize(msg.Width, contentH)
		return m, nil

	case tea.KeyMsg:
		// Global keys: tab switch with Ctrl+← / Ctrl+→ or number keys
		switch msg.String() {
		case "ctrl+c":
			return m, tea.Quit
		case "tab":
			prev := m.activeTab
			m.activeTab = (m.activeTab + 1) % len(tabNames)
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "shift+tab":
			prev := m.activeTab
			m.activeTab = (m.activeTab - 1 + len(tabNames)) % len(tabNames)
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "!":
			prev := m.activeTab
			m.activeTab = tabIntro
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "@":
			prev := m.activeTab
			m.activeTab = tabHosts
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "#":
			prev := m.activeTab
			m.activeTab = tabModules
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "$":
			prev := m.activeTab
			m.activeTab = tabSelection
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "%":
			prev := m.activeTab
			m.activeTab = tabBuilder
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "¨", "^":
			prev := m.activeTab
			m.activeTab = tabInstaller
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "&":
			prev := m.activeTab
			m.activeTab = tabScripts
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "*":
			prev := m.activeTab
			m.activeTab = tabDisko
			m, cmd := m.onTabSwitch(prev)
			return m, cmd
		case "q":
			// Only quit from Intro tab
			if m.activeTab == tabIntro {
				return m, tea.Quit
			}
		}
	}

	// Delegate to active tab
	var cmd tea.Cmd
	switch m.activeTab {
	case tabHosts:
		m.hosts, cmd = m.hosts.Update(msg)
	case tabModules:
		m.modules, cmd = m.modules.Update(msg)
	case tabSelection:
		m.selection, cmd = m.selection.Update(msg)
	case tabBuilder:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			if msg.String() == "enter" {
				presetName := m.hosts.SelectedPreset()
				modules := m.selection.GetSelected()
				if presetName != "" && len(modules) > 0 {
					cmd = m.builder.StartBuild(presetName, m.presetsDir, modules)
					return m, cmd
				}
			}
		}
		m.builder, cmd = m.builder.Update(msg)
	case tabInstaller:
		m.installer, cmd = m.installer.Update(msg)
	case tabScripts:
		m.scripts, cmd = m.scripts.Update(msg)
	case tabDisko:
		m.disko, cmd = m.disko.Update(msg)
	}

	return m, cmd
}

func (m model) onTabSwitch(prevTab int) (model, tea.Cmd) {
	switch m.activeTab {
	case tabSelection:
		m.selection.Refresh()
	case tabBuilder:
		return m, m.builder.FocusInput()
	case tabInstaller:
		m.installer.RefreshFlakes(m.hosts.SelectedPreset(), m.hosts.SelectedHostName())
	case tabScripts:
		m.scripts.Refresh()
	case tabDisko:
		m.disko.Refresh()
	}
	return m, nil
}

func (m model) View() string {
	// ── Tab bar ─────────────────────────────────────────────────
	var tabs []string
	for i, name := range tabNames {
		label := strings.ToUpper(name)
		if i == m.activeTab {
			tabs = append(tabs, styles.ActiveTab.Render("● "+label))
		} else {
			tabs = append(tabs, styles.InactiveTab.Render("  "+label))
		}
	}
	tabBar := styles.TabBar.Width(m.width).Render(lipgloss.JoinHorizontal(lipgloss.Top, tabs...))

	// ── Help bar (bottom) ───────────────────────────────────────
	var helpText string
	switch m.activeTab {
	case tabIntro:
		helpText = views.IntroHelpKeys()
	case tabHosts:
		helpText = m.hosts.HelpKeys()
	case tabModules:
		helpText = m.modules.HelpKeys()
	case tabSelection:
		helpText = m.selection.HelpKeys()
	case tabBuilder:
		helpText = m.builder.HelpKeys()
	case tabInstaller:
		helpText = m.installer.HelpKeys()
	case tabScripts:
		helpText = m.scripts.HelpKeys()
	case tabDisko:
		helpText = m.disko.HelpKeys()
	}
	helpBar := styles.HelpBar.Width(m.width).Render(helpText)

	// ── Content ─────────────────────────────────────────────────
	tabBarH := lipgloss.Height(tabBar)
	helpBarH := lipgloss.Height(helpBar)
	contentH := m.height - tabBarH - helpBarH - 1
	if contentH < 1 {
		contentH = 1
	}

	var content string
	switch m.activeTab {
	case tabIntro:
		content = views.IntroView(m.width, contentH)
	case tabHosts:
		content = m.hosts.View()
	case tabModules:
		content = m.modules.View()
	case tabSelection:
		content = m.selection.View()
	case tabBuilder:
		content = m.builder.View()
	case tabInstaller:
		content = m.installer.View()
	case tabScripts:
		content = m.scripts.View()
	case tabDisko:
		content = m.disko.View()
	}

	contentStyle := lipgloss.NewStyle().Width(m.width).Height(contentH)
	return tabBar + "\n" + contentStyle.Render(content) + "\n" + helpBar
}

func main() {
	p := tea.NewProgram(
		initialModel(),
		tea.WithAltScreen(),
		tea.WithMouseAllMotion(),
	)
	if _, err := p.Run(); err != nil {
		os.Exit(1)
	}
}
