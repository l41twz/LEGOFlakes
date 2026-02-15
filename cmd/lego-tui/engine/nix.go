package engine

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var Categories = []string{"system", "hardware", "apps", "services", "overlays"}

var CategoryDescriptions = map[string]string{
	"system":   "Configs base do NixOS e bootloader",
	"hardware": "Drivers, kernel e otimizações de HW",
	"apps":     "Programas de usuário e terminais",
	"services": "Docker, DBs, servidores e daemons",
	"overlays": "Modificações e patches no nixpkgs",
}

// ModuleInfo represents a discovered module
type ModuleInfo struct {
	Category string
	Name     string
	Purpose  string
	RelPath  string // category/name
	FullPath string
}

// ListModules scans modules/ directory
func ListModules(root string) []ModuleInfo {
	var modules []ModuleInfo
	modulesDir := filepath.Join(root, "modules")

	for _, cat := range Categories {
		catDir := filepath.Join(modulesDir, cat)
		entries, err := os.ReadDir(catDir)
		if err != nil {
			continue
		}
		for _, e := range entries {
			if e.IsDir() || !strings.HasSuffix(e.Name(), ".nix") {
				continue
			}
			name := strings.TrimSuffix(e.Name(), ".nix")
			fullPath := filepath.Join(catDir, e.Name())
			purpose := readPurpose(fullPath)
			modules = append(modules, ModuleInfo{
				Category: cat,
				Name:     name,
				Purpose:  purpose,
				RelPath:  cat + "/" + name,
				FullPath: fullPath,
			})
		}
	}
	return modules
}

func readPurpose(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	for _, line := range strings.Split(string(data), "\n") {
		trimmed := strings.TrimSpace(line)
		if strings.HasPrefix(trimmed, "# PURPOSE: ") {
			return strings.TrimSpace(strings.TrimPrefix(trimmed, "# PURPOSE: "))
		}
	}
	return ""
}

// ValidateNixSyntax runs nix-instantiate --parse on a file
func ValidateNixSyntax(path string) (bool, string) {
	cmd := exec.Command("nix-instantiate", "--parse", path)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return false, string(out)
	}
	return true, ""
}

// BuildFlake concatenates modules into a flake from template
func BuildFlake(root string, preset *Preset, modules []string, customName string) (string, error) {
	// Read template
	tmplPath := filepath.Join(root, "templates", "base-flake.nix")
	tmpl, err := os.ReadFile(tmplPath)
	if err != nil {
		return "", fmt.Errorf("template não encontrado: %w", err)
	}

	// Build module content
	var moduleContent strings.Builder
	indent := "          "
	for _, mod := range modules {
		modPath := filepath.Join(root, "modules", mod+".nix")
		data, err := os.ReadFile(modPath)
		if err != nil {
			continue
		}
		lines := strings.Split(string(data), "\n")
		if len(lines) < 4 {
			continue
		}
		modName := strings.TrimPrefix(lines[0], "# NIXOS-LEGO-MODULE: ")
		modPurpose := strings.TrimPrefix(lines[1], "# PURPOSE: ")
		body := strings.Join(lines[4:], "\n")

		moduleContent.WriteString("\n")
		moduleContent.WriteString(indent + "# ── " + modName + " ── " + modPurpose + "\n")
		for _, l := range strings.Split(body, "\n") {
			if strings.TrimSpace(l) == "" {
				moduleContent.WriteString("\n")
			} else {
				moduleContent.WriteString(indent + l + "\n")
			}
		}
	}

	// Replace placeholders
	flake := string(tmpl)
	replacements := map[string]string{
		"{{PRESET_NAME}}":            preset.Host.PresetName,
		"{{HOST_NAME}}":              preset.Host.HostName,
		"{{STATE_VERSION}}":          preset.Host.StateVersion,
		"{{USER_NAME}}":              preset.User.Name,
		"{{USER_DESCRIPTION}}":       preset.User.Description,
		"{{TIMEZONE}}":               preset.Locale.Timezone,
		"{{DEFAULT_LOCALE}}":         preset.Locale.DefaultLocale,
		"{{LC_ADDRESS}}":             preset.Locale.LcAddress,
		"{{LC_IDENTIFICATION}}":      preset.Locale.LcIdentification,
		"{{LC_MEASUREMENT}}":         preset.Locale.LcMeasurement,
		"{{LC_MONETARY}}":            preset.Locale.LcMonetary,
		"{{LC_NAME}}":                preset.Locale.LcName,
		"{{LC_NUMERIC}}":             preset.Locale.LcNumeric,
		"{{LC_PAPER}}":               preset.Locale.LcPaper,
		"{{LC_TELEPHONE}}":           preset.Locale.LcTelephone,
		"{{LC_TIME}}":                preset.Locale.LcTime,
		"{{KEYMAP}}":                 preset.Locale.Keymap,
		"{{MODULE_INJECTION_POINT}}": moduleContent.String(),
	}
	for k, v := range replacements {
		flake = strings.ReplaceAll(flake, k, v)
	}

	// Save
	suffix := customName
	if suffix == "" {
		suffix = time.Now().Format("20060102-150405")
	}
	outName := fmt.Sprintf("%s-%s.nix", preset.Host.PresetName, suffix)
	outPath := filepath.Join(root, "flakes", outName)
	if err := os.WriteFile(outPath, []byte(flake), 0644); err != nil {
		return "", err
	}

	// Update preset
	preset.Modules.Active = modules
	preset.Metadata.LastAppliedFlake = outName
	return outPath, nil
}

// NixosRebuild executes nixos-rebuild switch
func NixosRebuild(flakeDir, hostname string) (string, error) {
	cmd := exec.Command("sudo", "nixos-rebuild", "switch",
		"--flake", flakeDir+"#"+hostname, "--show-trace")
	out, err := cmd.CombinedOutput()
	return string(out), err
}
