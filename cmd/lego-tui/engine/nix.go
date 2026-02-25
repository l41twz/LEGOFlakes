package engine

import (
	"encoding/json"
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

// FlakeInput represents an external flake input from flake-inputs.json
type FlakeInput struct {
	Name           string `json:"name"`
	URL            string `json:"url"`
	Arg            string `json:"arg"`
	Attr           string `json:"attr"`
	FollowsNixpkgs bool   `json:"follows_nixpkgs"`
}

// LoadFlakeInputs reads flake-inputs.json from modules/overlays directory
func LoadFlakeInputs(root string) ([]FlakeInput, error) {
	path := filepath.Join(root, "modules", "overlays", "flake-inputs.json")
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return []FlakeInput{}, nil
		}
		return nil, fmt.Errorf("erro ao ler flake-inputs.json: %w", err)
	}
	var inputs []FlakeInput
	if err := json.Unmarshal(data, &inputs); err != nil {
		return nil, fmt.Errorf("erro ao parsear flake-inputs.json: %w", err)
	}
	return inputs, nil
}

// DevShell represents a development environment from devshells.json
type DevShell struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Packages    []string `json:"packages"`
	ShellHook   string   `json:"shellHook"`
}

// LoadDevShells reads devshells.json from modules/overlays directory
func LoadDevShells(root string) ([]DevShell, error) {
	path := filepath.Join(root, "modules", "overlays", "devshells.json")
	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return []DevShell{}, nil
		}
		return nil, fmt.Errorf("erro ao ler devshells.json: %w", err)
	}
	var shells []DevShell
	if err := json.Unmarshal(data, &shells); err != nil {
		return nil, fmt.Errorf("erro ao parsear devshells.json: %w", err)
	}
	return shells, nil
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

	// Load flake inputs
	flakeInputs, err := LoadFlakeInputs(root)
	if err != nil {
		return "", fmt.Errorf("erro ao carregar flake inputs: %w", err)
	}

	// Load devshells
	devShells, err := LoadDevShells(root)
	if err != nil {
		return "", fmt.Errorf("erro ao carregar devshells: %w", err)
	}

	// Generate flake input snippets
	flakeInputsSnippet, flakeOutputArgs, flakeSpecialArgs, moduleArgs := generateFlakeSnippets(flakeInputs)

	// Generate devshells snippet
	devShellsSnippet := generateDevShellsSnippet(devShells)

	// Build module wrapper args
	wrapperArgs := "pkgs, lib, config, pkgs-master"
	for _, a := range moduleArgs {
		wrapperArgs += ", " + a
	}

	// Build module content — each module becomes a separate entry in modules list
	var moduleContent strings.Builder
	indent := "        " // 8 spaces — aligns with modules list level
	bodyIndent := indent + "  "
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
		body := strings.TrimRight(strings.Join(lines[4:], "\n"), "\n ")

		moduleContent.WriteString("\n")
		moduleContent.WriteString(indent + "# ── " + modName + " ── " + modPurpose + "\n")
		moduleContent.WriteString(indent + "({ " + wrapperArgs + ", ... }: {\n")
		for _, l := range strings.Split(body, "\n") {
			if strings.TrimSpace(l) == "" {
				moduleContent.WriteString("\n")
			} else {
				moduleContent.WriteString(bodyIndent + l + "\n")
			}
		}
		moduleContent.WriteString(indent + "})\n")
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
		"{{FLAKE_INPUTS}}":           flakeInputsSnippet,
		"{{FLAKE_OUTPUT_ARGS}}":      flakeOutputArgs,
		"{{FLAKE_SPECIAL_ARGS}}":     flakeSpecialArgs,
		"{{DEVSHELLS_INJECTION}}":    devShellsSnippet,
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

// generateFlakeSnippets produces the 3 dynamic blocks + module arg list
func generateFlakeSnippets(inputs []FlakeInput) (inputsBlock, outputArgs, specialArgs string, moduleArgList []string) {
	if len(inputs) == 0 {
		return "", "", "", nil
	}

	var inLines, outArgs, saLines []string

	for _, fi := range inputs {
		// inputs block: zen-browser.url = "github:...";
		line := fmt.Sprintf("    %s.url = \"%s\";", fi.Name, fi.URL)
		if fi.FollowsNixpkgs {
			line += fmt.Sprintf("\n    %s.inputs.nixpkgs.follows = \"nixpkgs\";", fi.Name)
		}
		inLines = append(inLines, line)

		// output args: zen-browser,
		outArgs = append(outArgs, fi.Name+", ")

		// specialArgs: zen-browser-pkg = zen-browser.packages.${system}.default;
		saLines = append(saLines, fmt.Sprintf("        %s = %s.%s;", fi.Arg, fi.Name, fi.Attr))

		// module arg list
		moduleArgList = append(moduleArgList, fi.Arg)
	}

	inputsBlock = strings.Join(inLines, "\n")
	outputArgs = strings.Join(outArgs, "")
	specialArgs = strings.Join(saLines, "\n")
	return
}

func generateDevShellsSnippet(shells []DevShell) string {
	if len(shells) == 0 {
		return ""
	}

	var sb strings.Builder
	sb.WriteString("devShells.${system} = {\n")
	for _, shell := range shells {
		sb.WriteString(fmt.Sprintf("      \"%s\" = pkgs.mkShell {\n", shell.Name))
		sb.WriteString("        packages = with pkgs; [\n")
		for _, pkg := range shell.Packages {
			sb.WriteString(fmt.Sprintf("          %s\n", pkg))
		}
		sb.WriteString("        ];\n")
		if shell.ShellHook != "" {
			sb.WriteString(fmt.Sprintf("        shellHook = ''\n          %s\n        '';\n", shell.ShellHook))
		}
		sb.WriteString("      };\n")
	}
	sb.WriteString("    };\n")
	return sb.String()
}

// NixosRebuild executes nixos-rebuild switch
func NixosRebuild(flakePath, hostname string) (string, error) {
	// Root dir is project root
	flakeDir := filepath.Dir(flakePath)
	gitRoot := filepath.Dir(flakeDir)

	targetFlakeNix := filepath.Join(gitRoot, "flake.nix")

	data, err := os.ReadFile(flakePath)
	if err != nil {
		return "", fmt.Errorf("erro lendo flake gerado: %w", err)
	}
	if err := os.WriteFile(targetFlakeNix, data, 0644); err != nil {
		return "", fmt.Errorf("erro criando flake.nix na raiz: %w", err)
	}

	addCmd := exec.Command("git", "add", "flakes", "flake.nix")
	addCmd.Dir = gitRoot
	if err := addCmd.Run(); err != nil {
		fmt.Printf("Aviso: Falha ao rastrear arquivos no git: %v\n", err)
	}

	cmd := exec.Command("sudo", "nixos-rebuild", "switch",
		"--flake", gitRoot+"#"+hostname, "--show-trace")
	out, err := cmd.CombinedOutput()
	return string(out), err
}