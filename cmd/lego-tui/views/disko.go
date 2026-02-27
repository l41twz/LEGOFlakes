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

type diskoSubState int

const (
	diskoSubList diskoSubState = iota
	diskoSubAction
	diskoSubCreate
	diskoSubConfirmDelete
	diskoSubConfirmRun
	diskoSubRun
	diskoSubResult
)

type diskoResult struct {
	output string
	err    error
}

type diskoEditorFinished struct{ err error }

// ── Disko list item ──────────────────────────────────────────
type diskoItem struct {
	name string
	path string
}

func (d diskoItem) Title() string       { return d.name } // Cream color via delegate
func (d diskoItem) Description() string { return d.path } // Muted color via delegate
func (d diskoItem) FilterValue() string { return d.name }

// ── Action item ──────────────────────────────────────────────
// reusing actionItem from scripts.go if public, or redefining locally if private.
// scripts.go has 'actionItem' as private. I will redefine it here to avoid dependency issues or export it.
// I'll redefine locally as 'diskoActionItem' to be safe.
type diskoActionItem struct {
	title string
	desc  string
}

func (a diskoActionItem) Title() string       { return a.title }
func (a diskoActionItem) Description() string { return a.desc }
func (a diskoActionItem) FilterValue() string { return a.title }

// ── Model ────────────────────────────────────────────────────
type DiskoModel struct {
	subState    diskoSubState
	list        list.Model
	actionList  list.Model
	input       textinput.Model
	spinner     spinner.Model
	rootDir     string
	selected    string // Path of selected file
	output      string
	errMsg      string
	width       int
	height      int
	message     string
	isMountOnly bool
}

func NewDiskoModel(rootDir string) DiskoModel {
	sp := spinner.New()
	sp.Spinner = spinner.Line
	sp.Style = lipgloss.NewStyle().Foreground(styles.ColorWarning)

	emptyDelegate := list.NewDefaultDelegate()
	emptyList := list.New([]list.Item{}, emptyDelegate, 0, 0)
	emptyList.SetShowHelp(false)

	actionDelegate := list.NewDefaultDelegate()
	actionList := list.New([]list.Item{}, actionDelegate, 0, 0)
	actionList.SetShowHelp(false)
	actionList.Title = "Ações Disko"
	actionList.Styles.Title = styles.Subtitle

	ti := textinput.New()
	ti.Placeholder = "disk-layout.nix"
	ti.Focus()

	// Ensure dir exists
	os.MkdirAll(filepath.Join(rootDir, "disko"), 0755)

	return DiskoModel{
		subState:   diskoSubList,
		spinner:    sp,
		rootDir:    rootDir,
		list:       emptyList,
		actionList: actionList,
		input:      ti,
		width:      80,
		height:     24,
	}
}

func (m *DiskoModel) Refresh() {
	var items []list.Item
	dir := filepath.Join(m.rootDir, "disko")
	files, _ := filepath.Glob(filepath.Join(dir, "*.nix"))
	for _, f := range files {
		name := filepath.Base(f)
		items = append(items, diskoItem{name: name, path: f})
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
	l.Title = "Layouts Disko Disponíveis"
	l.Styles.Title = styles.Subtitle
	l.SetFilteringEnabled(false)
	l.SetShowHelp(false)
	m.list = l
}

func (m *DiskoModel) refreshActionList() {
	actions := []list.Item{
		diskoActionItem{title: "🚀 Executar Disko", desc: "Formatar e montar discos (PERIGOSO)"},
		diskoActionItem{title: "💽 Montar Apenas", desc: "Apenas montar as unidades configuradas"},
		diskoActionItem{title: "📝 Editar", desc: "Abrir no editor"},
		diskoActionItem{title: "🗑️  Deletar", desc: "Remover arquivo permanentemente"},
		diskoActionItem{title: "↩️  Voltar", desc: "Retornar à lista"},
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

func (m *DiskoModel) openEditor(path string) tea.Cmd {
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "micro"
	}
	c := exec.Command(editor, path)
	c.Stdin = os.Stdin
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	return tea.ExecProcess(c, func(err error) tea.Msg {
		return diskoEditorFinished{err}
	})
}

func (m DiskoModel) Init() tea.Cmd { return nil }

func (m DiskoModel) Update(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case diskoEditorFinished:
		if msg.err != nil {
			m.message = "Erro no editor: " + msg.err.Error()
		}
		m.subState = diskoSubList
		return m, nil
	case tea.WindowSizeMsg:
		m.SetSize(msg.Width, msg.Height)
	}

	switch m.subState {
	case diskoSubList:
		return m.updateList(msg)
	case diskoSubAction:
		return m.updateAction(msg)
	case diskoSubCreate:
		return m.updateCreate(msg)
	case diskoSubConfirmDelete:
		return m.updateConfirmDelete(msg)
	case diskoSubConfirmRun:
		return m.updateConfirmRun(msg)
	case diskoSubRun:
		return m.updateRun(msg)
	case diskoSubResult:
		return m.updateResult(msg)
	}
	return m, nil
}

func (m DiskoModel) updateList(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if item, ok := m.list.SelectedItem().(diskoItem); ok {
				m.selected = item.path
				m.subState = diskoSubAction
				m.refreshActionList()
			}
			return m, nil
		case "n":
			m.subState = diskoSubCreate
			m.input.SetValue("")
			m.input.Focus()
			return m, textinput.Blink
		case "d":
			if item, ok := m.list.SelectedItem().(diskoItem); ok {
				m.selected = item.path
				m.subState = diskoSubConfirmDelete
			}
			return m, nil
		case "e":
			if item, ok := m.list.SelectedItem().(diskoItem); ok {
				m.selected = item.path
				return m, m.openEditor(m.selected)
			}
			return m, nil
		}
	}

	var cmd tea.Cmd
	m.list, cmd = m.list.Update(msg)
	return m, cmd
}

func (m DiskoModel) updateAction(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if item, ok := m.actionList.SelectedItem().(diskoActionItem); ok {
				switch item.title {
				case "🚀 Executar Disko":
					m.isMountOnly = false
					m.subState = diskoSubConfirmRun
					return m, nil
				case "💽 Montar Apenas":
					m.isMountOnly = true
					m.subState = diskoSubConfirmRun
					return m, nil
				case "📝 Editar":
					return m, m.openEditor(m.selected)
				case "🗑️  Deletar":
					m.subState = diskoSubConfirmDelete
					return m, nil
				case "↩️  Voltar":
					m.subState = diskoSubList
					return m, nil
				}
			}
		case "esc":
			m.subState = diskoSubList
			return m, nil
		}
	}
	var cmd tea.Cmd
	m.actionList, cmd = m.actionList.Update(msg)
	return m, cmd
}

func (m DiskoModel) updateCreate(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			name := m.input.Value()
			if name == "" {
				return m, nil
			}
			if !strings.HasSuffix(name, ".nix") {
				name += ".nix"
			}
			path := filepath.Join(m.rootDir, "disko", name)

			f, err := os.Create(path)
			if err != nil {
				m.message = "Erro ao criar: " + err.Error()
				m.subState = diskoSubList
				return m, nil
			}
			// Default disko template
			f.WriteString(`{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
`)
			f.Close()

			m.selected = path
			m.Refresh()
			m.subState = diskoSubList
			return m, m.openEditor(path)

		case "esc":
			m.subState = diskoSubList
			return m, nil
		}
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(msg)
	return m, cmd
}

func (m DiskoModel) updateResult(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter", "esc":
			m.subState = diskoSubList
			m.output = ""
			m.errMsg = ""
			return m, nil
		}
	}
	return m, nil
}

func (m DiskoModel) updateConfirmDelete(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			err := os.Remove(m.selected)
			if err != nil {
				m.message = "Erro ao deletar: " + err.Error()
			} else {
				m.message = "🗑️ Layout deletado!"
			}
			m.Refresh()
			m.subState = diskoSubList
			return m, nil
		case "n", "N", "esc":
			m.subState = diskoSubList
			return m, nil
		}
	}
	return m, nil
}

func (m DiskoModel) updateConfirmRun(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "y", "Y":
			m.subState = diskoSubRun
			return m, tea.Batch(m.spinner.Tick, m.runDisko())
		case "n", "N", "esc":
			m.subState = diskoSubList
			return m, nil
		}
	}
	return m, nil
}

func (m DiskoModel) updateRun(msg tea.Msg) (DiskoModel, tea.Cmd) {
	switch msg := msg.(type) {
	case diskoResult:
		if msg.err != nil {
			m.errMsg = msg.err.Error()
			m.output = msg.output
		} else {
			m.output = msg.output
		}
		m.subState = diskoSubResult
		return m, nil
	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}
	return m, nil
}

func (m DiskoModel) runDisko() tea.Cmd {
	return func() tea.Msg {
		mode := "disko"
		if m.isMountOnly {
			mode = "mount"
		}
		// sudo nix run github:nix-community/disko -- --mode <mode> <file>
		cmd := exec.Command("sudo", "nix", "run", "github:nix-community/disko", "--", "--mode", mode, m.selected)
		out, err := cmd.CombinedOutput()
		if err != nil {
			return diskoResult{output: string(out), err: err}
		}

		destDir := "/mnt/etc/nixos"
		exec.Command("sudo", "mkdir", "-p", destDir).Run()

		destFile := filepath.Join(destDir, "disko.nix")
		cpCmd := exec.Command("sudo", "cp", m.selected, destFile)
		if cpOut, cpErr := cpCmd.CombinedOutput(); cpErr != nil {
			return diskoResult{output: string(out) + "\nErro ao copiar para /mnt: " + string(cpOut), err: cpErr}
		}

		return diskoResult{output: string(out) + fmt.Sprintf("\nLayout copiado para %s com sucesso.", destFile), err: nil}
	}
}

func (m DiskoModel) HelpKeys() string {
	switch m.subState {
	case diskoSubList:
		return "enter: confirmar/ações • n: novo • d: deletar • e: editar"
	case diskoSubAction:
		return "enter: selecionar • esc: voltar"
	case diskoSubCreate:
		return "enter: criar (abre editor) • esc: cancelar"
	case diskoSubConfirmDelete:
		return "y: confirmar • n/esc: cancelar"
	case diskoSubConfirmRun:
		if m.isMountOnly {
			return "y: MONTAR UNIDADES • n: cancelar"
		}
		return "y: DESTRUIR DADOS E FORMATAR • n: cancelar"
	case diskoSubRun:
		return "aguarde..."
	case diskoSubResult:
		return "enter/esc: voltar"
	}
	return ""
}

func (m DiskoModel) View() string {
	var s string

	switch m.subState {
	case diskoSubList:
		title := styles.Subtitle.Render("LAYOUTS DE PARTICIONAMENTO (DISKO)")
		status := ""
		if m.message != "" {
			status = "\n" + styles.MutedStyle.Render(m.message)
		}
		s = title + "\n\n" + m.list.View() + status

	case diskoSubAction:
		s = m.actionList.View()

	case diskoSubCreate:
		title := styles.Subtitle.Render("NOVO LAYOUT DE DISCO")
		s = title + "\n\n  Nome do arquivo (.nix):\n  " + m.input.View()

	case diskoSubConfirmDelete:
		title := styles.Subtitle.Render("CONFIRMAR DELEÇÃO")
		fname := filepath.Base(m.selected)
		warn := styles.WarningStyle.Render(fmt.Sprintf(
			"\n  ⚠️  Deletar layout '%s'?\n", fname))
		s = title + warn

	case diskoSubConfirmRun:
		fname := filepath.Base(m.selected)
		if m.isMountOnly {
			title := styles.Subtitle.Render("MONTAR DISCO?")
			warn := styles.WarningStyle.Render(fmt.Sprintf(
				"\n  ⚠️  Apenas montar as unidades configuradas em '%s'?\n  (Nenhum dado será deletado)\n", fname))
			s = title + warn
		} else {
			title := styles.Subtitle.Render("PERIGO: formatar disco?")
			warn := styles.ErrorStyle.Render(fmt.Sprintf(
				"\n  ⚠️  ATENÇÃO: Isso irá DESTRUIR DADOS no disco configurado em '%s'.\n  Tem certeza absoluta?\n", fname))
			s = title + warn
		}

	case diskoSubRun:
		if m.isMountOnly {
			title := styles.Subtitle.Render("MONTANDO DISCO")
			s = title + "\n\n  " + m.spinner.View() + " Montando..."
		} else {
			title := styles.Subtitle.Render("EXECUTANDO DISKO")
			s = title + "\n\n  " + m.spinner.View() + " Formatando e montando..."
		}

	case diskoSubResult:
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
			resStyle.Render(fmt.Sprintf("  %s Operação finalizada", icon)) + "\n"

		if m.errMsg != "" {
			s += styles.MutedStyle.Render("  Erro: "+m.errMsg) + "\n"
		}

		s += "\n" + styles.MutedStyle.Render(strings.TrimSpace(out))
	}

	return lipgloss.NewStyle().Padding(1, 2).Render(s)
}

func (m *DiskoModel) SetSize(w, h int) {
	m.width = w
	m.height = h
	m.list.SetSize(w-4, h-8)
	m.actionList.SetSize(w-4, h-6)
}
