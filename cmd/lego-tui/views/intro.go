package views

import (
	"LEGOFlakes/cmd/lego-tui/styles"

	"github.com/charmbracelet/lipgloss"
)

// IntroHelpKeys returns contextual help text for the intro view
func IntroHelpKeys() string {
	return "tab/shift+tab: navegar • shift+1 a shift+8: ir para aba 1-8 • q: sair"
}

// IntroView returns the static welcome screen
func IntroView(width, height int) string {
	logo := lipgloss.NewStyle().
		Bold(true).
		Foreground(styles.ColorPrimary).
		Align(lipgloss.Center).
		Width(width).
		Render("🧱  NixOS LEGO System Builder  🧱")

	desc := lipgloss.NewStyle().
		Foreground(styles.ColorText).
		Align(lipgloss.Center).
		Width(width).
		MarginTop(1).
		Render("Sistema modular de configuração NixOS")

	features := lipgloss.NewStyle().
		Foreground(styles.ColorMuted).
		Width(width).
		Align(lipgloss.Center).
		MarginTop(1).
		Render(`Este sistema permite que você:
• Crie módulos atômicos de configuração
• Monte diferentes presets (hosts) para a mesma máquina
• Combine módulos como blocos de LEGO`)

	concepts := lipgloss.NewStyle().
		Foreground(styles.ColorText).
		Width(width).
		Align(lipgloss.Center).
		MarginTop(1).
		Render(
			lipgloss.NewStyle().Foreground(styles.ColorAccent).Bold(true).Render("MÓDULO") + "  → Bloco de configuração específico (ex: bluetooth)\n" +
				lipgloss.NewStyle().Foreground(styles.ColorAccent).Bold(true).Render("PRESET") + "  → Conjunto de módulos + configurações de host\n" +
				lipgloss.NewStyle().Foreground(styles.ColorAccent).Bold(true).Render("FLAKE") + "   → Arquivo final gerado para aplicar no sistema")

	editorAVISO := lipgloss.NewStyle().Foreground(styles.ColorText).Width(width).Align(lipgloss.Center).MarginTop(1).Render(
		"Para ativar a extensão gemini no editor de texto, vá na aba scripts e execute editor-setup.nu\n" +
			"Gemini plugin: (Alt+h abre prompt para perguntas)\n" +
			"Gemini API key: (Vá na aba scripts edite gemini-key.nu e execute gemini-key.nu)")

	editorHint := styles.MutedStyle.Width(width).Align(lipgloss.Center).MarginTop(1).Render(
		"Editor padrão: Micro (Ctrl+S salvar, Ctrl+Q sair, Ctrl+E comandos, Ctrl+E tree para navegar)\n")

	return lipgloss.JoinVertical(lipgloss.Center,
		"", logo, desc, features, concepts, editorAVISO, editorHint)
}
