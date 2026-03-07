# NixOS LEGO System Builder 🧱

Um construtor de configurações NixOS moderno e modular, projetado para clareza e eficiência. Monte seu sistema NixOS como blocos de LEGO usando módulos atômicos, layouts de disco declarativos (Disko) e uma TUI (Interface de Terminal) interativa e intuitiva.

## ✨ Principais Funcionalidades

- **🚀 TUI em Go**: Uma interface interativa super rápida construída com Bubble Tea para selecionar seus módulos, configurar o sistema e compilar seu Flake com facilidade.
- **🧩 Arquitetura Modular ("Zero-Header")**: Módulos atômicos focados unicamente na declaração. Chega de cabeçalhos complexos – a TUI agrupa os módulos em uma configuração válida automaticamente.
- **🛠️ Sistema de Presets via TOML**: Salve perfis completos de hosts e usuários em arquivos `.toml` simples. Personalize sua build em segundos.
- **💾 Integração Profunda com Disko**: Layouts prontos para uso em diferentes cenários (`nvme.nix`, `sda.nix`, `vda.nix` para VMs).
- **🤖 Ecossistema e Assistência de IA**: Suporte nativo e documentado para rodar um hub de IA local (Ollama com modelos Llama/Qwen) e criar um segundo cérebro inteligente usando Khoj integrado ao Obsidian. Assistência de IA estendida até o seu CLI/Editor (Micro + Gemini).
- **🐚 Orquestração e Instalação em Nushell**: Scripts poderosos e legíveis para lidar com o particionamento, formatação, cópia das configurações e instalação final do NixOS no hardware.
- **💿 Geração de ISO Customizada**: Construa sua própria ISO live no diretório `iso/` para hospedar suas ferramentas favoritas antes mesmo de instalar o sistema.

## 📐 Arquitetura do Projeto

O projeto é estruturado de forma a separar estritamente o motor de geração das peças de configuração:

```text
├── cmd/lego-tui/      # Motor e código fonte da TUI interativa (Go)
├── config/            # Configurações de ferramentas como o Micro editor e plugins
├── disko/             # Layouts declarativos de disco prontos para uso (nvme, sda, vda)
├── flakes/            # Extensões e Flakes gerados pelo lego-tui
├── iso/               # Módulos para geração de Live ISO do NixOS
├── modules/           # As "peças de LEGO": módulos de sistema, apps, hardware, etc.
├── presets/           # Perfis de Host em modo TOML
├── scripts/           # Scripts core em Nushell (#1, #2, #3) para formatação e instalação
└── templates/         # Template base usado como alicerce do motor de Flake
```

### O Conceito de Módulo "Zero-Header"
Os módulos no LEGOFlakes são recortes puros de código Nix. Sem cabeçalhos engessados ou declarações de importação — apenas a configuração bruta e identificadores do TUI comentados.

Exemplo de `modules/hardware/bluetooth.nix`:
```nix
# NIXOS-LEGO-MODULE: bluetooth-core
# PURPOSE: Enable bluetooth services and GUI
# CATEGORY: hardware
# ---
hardware.bluetooth.enable = true;
services.blueman.enable = true;
```

## 🛠️ Instalação em Novo Hardware (Nova Abordagem)

O sistema conta com um novo instalador modular usando scripts `nu` de instalação direta para um novo NixOS. 

### Pré-requisitos Iniciais
- Uma ISO Live qualquer do NixOS ou a ISO compilada de `/iso` (com Flakes e Nushell)
- Conexão com internet
- Partição e disco definidos (Verifique `lsblk` para usar `/dev/nvme0n1` ou `/dev/sda`)

### Passo a Passo

1. **Clone do Repositório (no Live USB):**
```bash
git clone https://github.com/l41twz/LEGOFlakes.git
cd LEGOFlakes
```

2. **Formatação e Estruturação Disko (#1):**
Executa seu layout Disko escolhido e monta em `/mnt`.
```bash
sudo nu scripts/#1-prepare.nu
```

3. **Cópia do Projeto (#2):**
Move o blueprint do seu sistema para a área de instalação local antes mesmo do NixOS existir.
```bash
sudo nu scripts/#2-copy-dflakes-pnixos.nu
```

4. **Instalação do Sistema (#3):**
Realiza a detecção, criação automática de arquivos finais como base e finaliza a geração do Flake no disco do host.
```bash
sudo nu scripts/#3-flake-installer-v2.nu
```

## 🤖 Integração com Editor (Micro + Gemini)

Projetamos um fluxo em  `config/micro` que injeta o Google Gemini direto na edição de texto.
Essa funcionalidade possibilita pedir ao Gemini para codar pedaços inteiros, ou avaliar a semântica Nix de um módulo enquanto você constrói o sistema.

1. Instale e configure o token com `nu scripts/gemini-key.nu`
2. Utilize o atalho ou comando no Micro para acionar `config/micro/gemini-query.nu`.

## 📜 Licença

Desenvolvido para uso pessoal, estudos em NixOS, e experimentações em automação com TUI/Go. 
Este projeto é licenciado sob a Licença MIT - consulte o arquivo `LICENSE` para mais detalhes.
