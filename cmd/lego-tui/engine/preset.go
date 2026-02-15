package engine

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/BurntSushi/toml"
)

type Preset struct {
	Host     HostConfig     `toml:"host"`
	User     UserConfig     `toml:"user"`
	Locale   LocaleConfig   `toml:"locale"`
	Modules  ModulesConfig  `toml:"modules"`
	Metadata MetadataConfig `toml:"metadata"`
}

type HostConfig struct {
	PresetName   string `toml:"preset_name"`
	HostName     string `toml:"host_name"`
	StateVersion string `toml:"state_version"`
}

type UserConfig struct {
	Name        string `toml:"name"`
	Description string `toml:"description"`
}

type LocaleConfig struct {
	Timezone         string `toml:"timezone"`
	DefaultLocale    string `toml:"default_locale"`
	LcAddress        string `toml:"lc_address"`
	LcIdentification string `toml:"lc_identification"`
	LcMeasurement    string `toml:"lc_measurement"`
	LcMonetary       string `toml:"lc_monetary"`
	LcName           string `toml:"lc_name"`
	LcNumeric        string `toml:"lc_numeric"`
	LcPaper          string `toml:"lc_paper"`
	LcTelephone      string `toml:"lc_telephone"`
	LcTime           string `toml:"lc_time"`
	Keymap           string `toml:"keymap"`
}

type ModulesConfig struct {
	Active []string `toml:"active"`
}

type MetadataConfig struct {
	CreatedAt        string `toml:"created_at"`
	LastModified     string `toml:"last_modified"`
	LastAppliedFlake string `toml:"last_applied_flake"`
}

// LoadPreset reads a .toml preset file
func LoadPreset(path string) (*Preset, error) {
	var p Preset
	if _, err := toml.DecodeFile(path, &p); err != nil {
		return nil, fmt.Errorf("erro ao carregar preset: %w", err)
	}
	return &p, nil
}

// SavePreset writes a preset to .toml
func SavePreset(path string, p *Preset) error {
	p.Metadata.LastModified = time.Now().UTC().Format(time.RFC3339)
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return toml.NewEncoder(f).Encode(p)
}

// ListPresets returns all .toml files in presets/ dir
func ListPresets(presetsDir string) ([]PresetInfo, error) {
	entries, err := os.ReadDir(presetsDir)
	if err != nil {
		return nil, err
	}
	var result []PresetInfo
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".toml") {
			continue
		}
		info, _ := e.Info()
		name := strings.TrimSuffix(e.Name(), ".toml")
		result = append(result, PresetInfo{
			Name:     name,
			Path:     filepath.Join(presetsDir, e.Name()),
			Modified: info.ModTime(),
		})
	}
	return result, nil
}

type PresetInfo struct {
	Name     string
	Path     string
	Modified time.Time
}

// NewDefaultPreset creates a preset with sensible defaults
func NewDefaultPreset(name, userName string) *Preset {
	now := time.Now().UTC().Format(time.RFC3339)
	return &Preset{
		Host: HostConfig{
			PresetName:   name,
			HostName:     name,
			StateVersion: "24.05",
		},
		User: UserConfig{
			Name:        userName,
			Description: userName,
		},
		Locale: LocaleConfig{
			Timezone:         "America/Sao_Paulo",
			DefaultLocale:    "en_US.UTF-8",
			LcAddress:        "pt_BR.UTF-8",
			LcIdentification: "pt_BR.UTF-8",
			LcMeasurement:    "pt_BR.UTF-8",
			LcMonetary:       "pt_BR.UTF-8",
			LcName:           "pt_BR.UTF-8",
			LcNumeric:        "pt_BR.UTF-8",
			LcPaper:          "pt_BR.UTF-8",
			LcTelephone:      "pt_BR.UTF-8",
			LcTime:           "pt_BR.UTF-8",
			Keymap:           "br-abnt2",
		},
		Modules:  ModulesConfig{Active: []string{}},
		Metadata: MetadataConfig{CreatedAt: now, LastModified: now},
	}
}
