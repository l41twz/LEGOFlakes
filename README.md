# NixOS LEGO System Builder 🧱

Um construtor de configurações NixOS moderno e modular, projetado para clareza e eficiência. Monte seu setup NixOS como LEGO usando módulos atômicos e uma TUI (Interface de Terminal) intuitiva.

## ✨ Principais Funcionalidades

- **🚀 TUI em Go**: Uma interface interativa rápida e responsiva construída com Bubble Tea.
- **🧩 Arquitetura Modular**: Módulos atômicos "Zero-Header" que tornam a reutilização de configurações sem esforço.
- **🛠️ Sistema de Presets Automatizado**: Defina hosts e configurações de usuário via arquivos `.toml` simples.
- **💾 Integração com Disko**: Ferramentas de particionamento de disco integradas para instalações fáceis.
- **🔗 Flake Inputs Dinâmicos**: Declare flakes externos em um único JSON — sem editar o builder ou template.
- **🤖 Assistência de IA**: Integração profunda com Gemini para assistência no editor e ajuda na configuração.
- **🐚 Orquestração com Nushell**: Utiliza scripts shell modernos para operações de backend robustas.

## 🛠️ Instalação e Configuração

### Pré-requisitos
- [Nix](https://nixos.org/download.html) (com Flakes habilitados)
- [Go](https://go.dev/) (para compilar a TUI)
- [Nushell](https://www.nushell.sh/)

### Início Rápido
```bash
# Clone o repositório
git clone https://github.com/l41twz/LEGOFlakes.git
cd LEGOFlakes

# Compile a LEGO TUI
go build -o lego-tui ./cmd/lego-tui

# Configuração inicial (instala plugins do editor e prepara o ambiente)
nu scripts/prepare.nu

# Inicie a interface
./lego-tui
```

## 📐 Arquitetura

O projeto é estruturado para separar a lógica da configuração:

```text
├── cmd/lego-tui/      # Código fonte da TUI interativa em Go
├── modules/           # Módulos NixOS atômicos (sistema, hardware, apps, etc.)
├── flake-inputs.json  # Declaração de flakes externos (zen-browser, etc.)
├── presets/           # Configurações específicas de host (.toml)
├── scripts/           # Scripts de automação em Nushell
├── secrets/           # Arquivos de configuração de segredo
├── flakes/            # Saídas de Flakes geradas
└── templates/         # Templates Nix base usados para geração
```

### O Conceito de Módulo "Zero-Header"
Os módulos no LEGOFlakes são projetados para serem trechos puros de Nix. Sem cabeçalhos de função, sem imports — apenas a configuração bruta. O construtor envolve automaticamente esses trechos em módulos Nix válidos durante o processo de geração do Flake.

Exemplo em `modules/hardware/bluetooth.nix`:
```nix
# NIXOS-LEGO-MODULE: bluetooth-core
# PURPOSE: Enable bluetooth services and GUI
# CATEGORY: hardware
# ---
hardware.bluetooth.enable = true;
services.blueman.enable = true;
```

## 🚀 Fluxo de Trabalho

1. **Seleção de Host**: Escolha ou crie um preset de host (arquitetura, usuário, timezone).
2. **Seleção de Componentes**: Selecione módulos interativamente entre categorias (Sistema, Hardware, Apps, Serviços).
3. **Build**: Gere um `flake.nix` completo concatenando os módulos selecionados nos templates.
4. **Deploy**: Visualize as mudanças com um visualizador de diff integrado e aplique usando `nixos-rebuild`.

## 🤖 Integração com Editor

Recomendamos o uso do editor **Micro** com nosso plugin customizado **Gemini** (localizado em `config/micro`). Isso permite:
- Obter ajuda de IA enquanto edita os módulos.
- Formatar código Nix automaticamente.
- Gerenciar chaves de API com segurança através de `nu scripts/gemini-key.nu`.

## 📜 Licença

Este projeto é licenciado sob a Licença MIT - consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
