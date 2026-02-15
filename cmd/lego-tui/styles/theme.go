package styles

import "github.com/charmbracelet/lipgloss"

// Colors — Gruvbox-inspired palette
var (
	ColorPrimary   = lipgloss.Color("#83a598") // aqua
	ColorSecondary = lipgloss.Color("#b8bb26") // green
	ColorAccent    = lipgloss.Color("#fabd2f") // yellow
	ColorDanger    = lipgloss.Color("#fb4934") // red
	ColorWarning   = lipgloss.Color("#fe8019") // orange
	ColorMuted     = lipgloss.Color("#928374") // gray
	ColorText      = lipgloss.Color("#ebdbb2") // fg
	ColorBg        = lipgloss.Color("#282828") // bg
	ColorBgLight   = lipgloss.Color("#3c3836") // bg1
	ColorPurple    = lipgloss.Color("#d3869b") // purple
)

// Tab styles
var (
	ActiveTab = lipgloss.NewStyle().
			Bold(true).
			Foreground(ColorAccent).
			Underline(false).
			Padding(0, 2)

	InactiveTab = lipgloss.NewStyle().
			Foreground(ColorText).
			Padding(0, 2)

	TabBar = lipgloss.NewStyle().
		Border(lipgloss.NormalBorder(), false, false, true, false).
		BorderForeground(ColorMuted).
		MarginBottom(1)

	HelpBar = lipgloss.NewStyle().
		Border(lipgloss.NormalBorder(), true, false, false, false).
		BorderForeground(ColorMuted).
		Foreground(ColorMuted).
		Padding(1, 2)
)

// General
var (
	Title = lipgloss.NewStyle().
		Bold(true).
		Foreground(ColorPrimary).
		MarginBottom(1)

	Subtitle = lipgloss.NewStyle().
			Foreground(ColorAccent).
			Bold(true)

	HelpStyle = lipgloss.NewStyle().
			Foreground(ColorMuted).
			MarginTop(1)

	ErrorStyle = lipgloss.NewStyle().
			Foreground(ColorDanger).
			Bold(true)

	SuccessStyle = lipgloss.NewStyle().
			Foreground(ColorSecondary).
			Bold(true)

	WarningStyle = lipgloss.NewStyle().
			Foreground(ColorWarning)

	MutedStyle = lipgloss.NewStyle().
			Foreground(ColorMuted)

	BoxStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(ColorPrimary).
			Padding(1, 3)

	SelectedItem = lipgloss.NewStyle().
			Foreground(ColorSecondary).
			Bold(true)

	NormalItem = lipgloss.NewStyle().
			Foreground(ColorText)
)
