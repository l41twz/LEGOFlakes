# 🧱 Prompt de Coordenação — Criação de Módulos NixOS LEGO

> **INSTRUÇÕES PARA O AGENTE DE IA:**
> Este documento descreve com precisão exata como você deve criar módulos para o projeto **LEGOFlakes**.
> O usuário vai te anexar este arquivo junto com um ou mais arquivos de configuração NixOS (como `configuration.nix`, `hardware-configuration.nix`, trechos de código Nix avulsos, etc.) e te pedir para convertê-los em módulos LEGO.
> Siga **TODAS** as regras abaixo **SEM EXCEÇÃO**. Se qualquer regra for violada, o módulo resultante **quebrará** o sistema de build.

---

## 1. O Que É o Projeto LEGOFlakes

LEGOFlakes é um construtor de configurações NixOS modular. A ideia central é que configurações NixOS complexas sejam decompostas em **peças atômicas reutilizáveis** — como peças de LEGO. Cada peça é um arquivo `.nix` pequeno, focado em **uma única responsabilidade**, que fica na pasta `modules/` organizada por categoria.

Um programa TUI em Go (Bubble Tea) permite ao usuário selecionar quais módulos deseja. O builder então **concatena** esses módulos em um `flake.nix` final funcional, onde cada módulo é automaticamente envolvido em `({ pkgs, lib, config, pkgs-master, <flake-args...>, ... }: { ... })` pelo builder. Os argumentos extras (`pkgs-master` e quaisquer args de flakes externos definidos em `flake-inputs.json`) são injetados automaticamente. Por isso, **o módulo em si NUNCA deve conter esse wrapper** — ele é inserido automaticamente.

O resultado final (o `flake.nix` gerado) terá esta estrutura:

```nix
{
  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.meu-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Módulo base (identidade do host — gerado pelo template)
        ({ pkgs, lib, config, ... }: {
          networking.hostName = "meu-host";
          users.users."meu-usuario" = { ... };
          time.timeZone = "America/Sao_Paulo";
          system.stateVersion = "24.11";
          # ... etc
        })

        # ── bluetooth ── Enable Bluetooth support
        ({ pkgs, lib, config, pkgs-master, zen-browser-pkg, ... }: {  # ← WRAPPER DINÂMICO (args de flake-inputs.json)
          hardware.bluetooth.enable = true;
          services.blueman.enable = true;
          hardware.bluetooth.powerOnBoot = true;
        })                                   # ← O BUILDER FECHA AQUI

        # ── dev-tools ── Common system packages
        ({ pkgs, lib, config, pkgs-master, zen-browser-pkg, ... }: {  # ← MESMO WRAPPER
          environment.systemPackages = with pkgs; [
            git vim wget curl
          ];
        })                                   # ← FECHADO PELO BUILDER
      ];
    };
  };
}
```

**CONSEQUÊNCIA IMPORTANTE:** Como cada módulo LEGO vira um módulo NixOS separado na lista `modules`, o **NixOS module system faz merge automático** de atributos repetidos como `environment.systemPackages`, `nixpkgs.overlays`, etc. Isso significa que **dois módulos diferentes podem definir `environment.systemPackages`** sem conflito — as listas são fundidas automaticamente pelo Nix.

---

## 2. Anatomia Exata de um Módulo LEGO

Todo módulo LEGO é um arquivo `.nix` com a seguinte estrutura **obrigatória**:

```
LINHA 1: # NIXOS-LEGO-MODULE: <nome-do-modulo>
LINHA 2: # PURPOSE: <descrição curta em uma única linha, em inglês>
LINHA 3: # CATEGORY: <categoria>
LINHA 4: # ---
LINHA 5 em diante: <código Nix puro>
```

### 2.1 CABEÇALHO — Exatamente 4 Linhas

O cabeçalho **SEMPRE** tem exatamente 4 linhas. Nem mais, nem menos. O builder faz `lines[4:]` para extrair o corpo, ou seja, pula as 4 primeiras linhas.

| Linha | Formato | Descrição |
|-------|---------|-----------|
| 1 | `# NIXOS-LEGO-MODULE: <nome>` | Nome único, kebab-case (ex: `pipewire-audio`, `nvidia-gpu`, `dev-tools`). Não use espaços, underscores, ou camelCase. |
| 2 | `# PURPOSE: <texto>` | Uma frase curta em **inglês** descrevendo o que o módulo faz. Máximo ~80 caracteres. |
| 3 | `# CATEGORY: <cat>` | Uma das 5 categorias permitidas (ver seção 3). |
| 4 | `# ---` | Separador fixo. Exatamente `# ---`. Nada mais, nada menos. |

**EXEMPLOS CORRETOS:**
```
# NIXOS-LEGO-MODULE: pipewire-audio
# PURPOSE: Modern audio server with PulseAudio and JACK compatibility
# CATEGORY: hardware
# ---
```

```
# NIXOS-LEGO-MODULE: docker-engine
# PURPOSE: Docker container runtime with rootless support
# CATEGORY: services
# ---
```

**EXEMPLOS INCORRETOS (NUNCA FAÇA ISSO):**
```
# NIXOS-LEGO-MODULE: Docker Engine    ← ERRADO: espaços e maiúsculas
# PURPOSE:                             ← ERRADO: vazio
# CATEGORY: containerization           ← ERRADO: categoria inventada
# ---
# Extra comment                        ← ERRADO: 5ª linha de cabeçalho
```

### 2.2 CORPO — Código Nix Puro

Após a linha 4 (`# ---`), vem **exclusivamente código Nix puro**: atribuições de atributos no formato do NixOS module system.

**O que PODE ter:**
- Atribuições diretas: `services.openssh.enable = true;`
- Atribuições aninhadas: `services.pipewire = { enable = true; alsa.enable = true; };`
- Listas de pacotes: `environment.systemPackages = with pkgs; [ git vim ];`
- Overlays: `nixpkgs.overlays = [ (final: prev: { ... }) ];`
- Opções com `lib.mkDefault`, `lib.mkForce`, `lib.mkIf`, etc.
- Comentários Nix explicativos dentro do corpo
- Referências a `pkgs`, `lib`, `config`, `pkgs-master` e args de flakes externos (todos injetados pelo builder)
- Referências a args declarados em `flake-inputs.json` (ex: `zen-browser-pkg`)

**O que NUNCA pode ter:**
- ❌ Headers de função: `{ pkgs, lib, config, ... }:`
- ❌ Chaves externas envolvendo tudo: `{ ... }` (o builder já faz isso)
- ❌ `imports = [ ... ];`
- ❌ `require = [ ... ];`
- ❌ Definição de `networking.hostName` (está no template base)
- ❌ Definição de `system.stateVersion` (está no template base)
- ❌ Definição de `users.users.<nome>` principal (está no template base)
- ❌ Definição de `time.timeZone` (está no template base)
- ❌ Definição de locale (`i18n.defaultLocale`, `i18n.extraLocaleSettings`) (está no template base)
- ❌ Definição de `console.keyMap` (está no template base)
- ❌ Qualquer `let ... in` no nível raiz (crie um attrset aninhado se necessário)
- ❌ Expressões Nix avulsas que não sejam atribuições de atributos

---

## 3. As 5 Categorias — Sem Exceções

Existem **exatamente 5 categorias**. Cada módulo pertence a **uma e somente uma** delas. Não invente categorias. Se um módulo parece não se encaixar, escolha a **mais próxima**.

| Categoria | Pasta | Quando Usar | Exemplos Típicos |
|-----------|-------|-------------|------------------|
| `system` | `modules/system/` | Configurações fundamentais do SO: bootloader, kernel, swap, systemd, fontes do sistema, Nix settings, garbage collection | `boot.loader.*`, `zramSwap.*`, `nix.settings.*`, `fonts.*`, `systemd.*` |
| `hardware` | `modules/hardware/` | Drivers, dispositivos físicos, áudio, vídeo, GPU, rede Wi-Fi, Bluetooth, impressoras, sensores | `hardware.*`, `services.pipewire.*`, `services.blueman.*`, `hardware.nvidia.*`, `hardware.opengl.*` |
| `apps` | `modules/apps/` | Programas de usuário final: editores, navegadores, terminais, ferramentas CLI, utilitários, shells, ambientes desktop, window managers | `environment.systemPackages`, `programs.firefox.*`, `programs.git.*`, `services.xserver.desktopManager.*` |
| `services` | `modules/services/` | Daemons, serviços em background, servidores: SSH, Docker, bancos de dados, web servers, gaming (Steam), virtualização | `services.openssh.*`, `virtualisation.docker.*`, `services.nginx.*`, `programs.steam.*` |
| `overlays` | `modules/overlays/` | Modificações customizadas do nixpkgs: patches, overrides de versão, pacotes personalizados | `nixpkgs.overlays`, `nixpkgs.config.*` |

### 3.1 Regras de Desambiguação

- **PipeWire/PulseAudio** → `hardware` (é infraestrutura de áudio do hardware)
- **NVIDIA/AMD GPU** → `hardware` (são drivers de hardware)
- **Desktop Environment (GNOME, KDE, Hyprland)** → `apps` (é software de interface)
- **Window Manager (i3, Sway)** → `apps` (é software de interface)
- **Steam** → `services` (roda como serviço/daemon com gamemode)
- **Docker/Podman** → `services` (são daemons de virtualização)
- **Firewall** → `services` (é um serviço de rede)
- **Fonts** → `system` (são recursos do sistema)
- **nixpkgs.config.allowUnfree** → `overlays` (é configuração do nixpkgs)

---

## 4. Nomenclatura de Arquivos

O arquivo do módulo deve ser salvo como:

```
modules/<categoria>/<nome-descritivo>.nix
```

Regras:
- **kebab-case** para o nome do arquivo (ex: `nvidia-gpu.nix`, `pipewire-audio.nix`, `dev-tools.nix`)
- O nome do arquivo deve ser **descritivo e conciso** — o usuário precisa entender o que é apenas pelo nome
- O `<nome>` no cabeçalho do módulo (`# NIXOS-LEGO-MODULE: <nome>`) deve ser **idêntico** ao nome do arquivo sem a extensão `.nix`
- Exemplos válidos:
  - `modules/hardware/pipewire-audio.nix` com `# NIXOS-LEGO-MODULE: pipewire-audio`
  - `modules/apps/firefox-browser.nix` com `# NIXOS-LEGO-MODULE: firefox-browser`

---

## 5. Princípio da Atomicidade — Quando Dividir e Quando Unir

### 5.1 Um Módulo = Uma Responsabilidade Coerente

Cada módulo deve representar **uma funcionalidade lógica completa** que o usuário ativaria ou desativaria como um todo. Pense: "Se o usuário desmarcar este módulo na TUI, o que deixaria de funcionar?" Se a resposta é **uma coisa clara**, o módulo está bem dimensionado.

### 5.2 Quando DIVIDIR em Múltiplos Módulos

Divida quando o arquivo de origem contém funcionalidades **independentes entre si**. Exemplos:

- Um `configuration.nix` que tem Bluetooth E PipeWire → 2 módulos: `bluetooth.nix` + `pipewire-audio.nix`
- Um arquivo com Docker E SSH → 2 módulos: `docker-engine.nix` + `ssh-server.nix`
- Um arquivo com GNOME, pacotes de dev, e Steam → 3 módulos: `gnome-desktop.nix` + `dev-tools.nix` + `steam-gaming.nix`

**Regra prática:** Se um usuário poderia razoavelmente querer X mas não Y, eles devem ser módulos separados.

### 5.3 Quando MANTER em um Único Módulo

Mantenha junto quando as configurações são **interdependentes** e não fazem sentido separadas:

- PipeWire + ALSA + PulseAudio compat + JACK → tudo junto em `pipewire-audio.nix` (PipeWire sem ALSA seria inútil)
- NVIDIA driver + OpenGL + Vulkan → tudo junto em `nvidia-gpu.nix`
- SSH server + suas configurações de segurança → tudo junto em `ssh-server.nix`

### 5.4 environment.systemPackages — Caso Especial

Pacotes em `environment.systemPackages` devem ir no módulo **da funcionalidade a que pertencem**, não em um módulo genérico de "pacotes" caso se refiram a algo sistêmico. 
**NOTA IMPORTANTE SOBRE DESENVOLVIMENTO:** Pacotes genéricos de programação/desenvolvimento que não devem sujar o sistema devem ser postos no `modules/overlays/devshells.json` como um `devShell` isolado. Os exemplos abaixo servem apenas para pacotes que DE FATO devem estar disponíveis no sistema global.

Exemplos de pacotes de sistema:
- `nmap`, `wireshark` → módulo `network-tools.nix` (categoria `apps`)
- `firefox`, `chromium` → módulo `web-browsers.nix` (categoria `apps`)

Se um conjunto de pacotes não tem tema em comum, aí sim crie um módulo genérico como `extra-packages.nix`.

---

## 6. Módulos de Referência Reais do Projeto

Aqui estão os módulos existentes no projeto. Use-os como **modelo exato** para formatação, estilo e nível de detalhe:

### 6.1 `modules/hardware/bluetooth.nix`
```nix
# NIXOS-LEGO-MODULE: bluetooth
# PURPOSE: Enable Bluetooth support
# CATEGORY: hardware
# ---
hardware.bluetooth.enable = true;
services.blueman.enable = true;
hardware.bluetooth.powerOnBoot = true;
```

### 6.2 `modules/services/ssh-server.nix`
```nix
# NIXOS-LEGO-MODULE: ssh-server
# PURPOSE: OpenSSH server configuration
# CATEGORY: services
# ---
services.openssh.enable = true;
services.openssh.settings.PermitRootLogin = "no";
services.openssh.settings.PasswordAuthentication = false;
```

### 6.4 `modules/system/zram-swap.nix`
```nix
# NIXOS-LEGO-MODULE: zram-swap
# PURPOSE: Enable ZRAM compressed swap
# CATEGORY: system
# ---
zramSwap.enable = true;
zramSwap.memoryPercent = 50;
```

### 6.5 `modules/overlays/custom-packages.nix`
```nix
# NIXOS-LEGO-MODULE: custom-packages
# PURPOSE: Custom package versions and patches
# CATEGORY: overlays
# ---
nixpkgs.overlays = [
  (final: prev: {
    # Exemplo: override de versão de pacote
    # myCustomVim = prev.vim.overrideAttrs (oldAttrs: {
    #   # customizações aqui
    # });
  })
];
```

---

## 7. Procedimento de Conversão Passo a Passo

Quando o usuário te entregar um arquivo de configuração NixOS (ou trecho de código Nix), siga este procedimento:

### Passo 1 — Ler e Entender
Leia todo o conteúdo anexado. Identifique **todas** as funcionalidades presentes. Liste-as mentalmente.

### Passo 2 — Descartar o que pertence ao Template Base
Remova/ignore completamente:
- `networking.hostName = "...";`
- `system.stateVersion = "...";`
- `users.users.<qualquer>` (a definição principal do usuário)
- `time.timeZone = "...";`
- `i18n.defaultLocale = "...";` e `i18n.extraLocaleSettings`
- `console.keyMap = "...";`
- `networking.networkmanager.enable = true;`
- Headers de função como `{ config, pkgs, lib, ... }:`
- Chaves `{ }` que envolvem todo o conteúdo (o wrapper do módulo)
- Linhas de `imports = [ ... ];`

Essas configurações **já existem no template base** do LEGOFlakes e serão preenchidas pelo preset TOML do usuário.

### Passo 3 — Agrupar por Funcionalidade
Agrupe as linhas restantes por funcionalidade lógica coerente. Cada grupo será um módulo.

### Passo 4 — Classificar por Categoria
Para cada grupo, determine a categoria correta usando a tabela da seção 3 e as regras de desambiguação da seção 3.1.

### Passo 5 — Nomear
Crie um nome kebab-case descritivo para cada módulo. Esse nome será usado tanto no cabeçalho quanto no nome do arquivo.

### Passo 6 — Escrever o Módulo
Para cada módulo, escreva o arquivo completo seguindo a anatomia da seção 2:
1. As 4 linhas de cabeçalho (exatamente como especificado)
2. O corpo com código Nix puro
3. **Não adicione linhas em branco extras** no final do arquivo (máximo 1 newline final)
4. **Não adicione comentários desnecessários** — o código Nix deve ser autoexplicativo. Comentários só quando houver algo não óbvio.

### Passo 7 — Informar o Caminho de Salvamento
Diga ao usuário exatamente onde salvar cada arquivo:
```
modules/<categoria>/<nome>.nix
```

### Passo 8 — Validar Mentalmente
Antes de entregar, verifique:
- [ ] O cabeçalho tem EXATAMENTE 4 linhas?
- [ ] A categoria é UMA das 5 permitidas?
- [ ] O nome no cabeçalho bate com o nome do arquivo?
- [ ] O código é Nix PURO — sem headers de função, sem imports, sem chaves externas?
- [ ] NÃO conflita com o template base (hostname, stateVersion, user, timezone, locale, keymap)?
- [ ] Nenhum `let ... in` no nível raiz?
- [ ] Os pacotes usam `with pkgs;` quando aplicável?
- [ ] Cada módulo tem UMA responsabilidade coerente?
- [ ] Se há `environment.systemPackages` em vários módulos, eles estão em módulos **diferentes** com contextos diferentes? (Isso é OK — o NixOS module system faz merge automático das listas)

---

## 8. Exemplo Completo de Conversão

### ENTRADA (arquivo do usuário):
```nix
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "meu-pc";

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "pt_BR.UTF-8";

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.joao = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  environment.systemPackages = with pkgs; [
    firefox
    git
    vim
    vscode
    htop
    wget
  ];

  services.openssh.enable = true;

  system.stateVersion = "24.11";
}
```

### SAÍDA (módulos LEGO gerados):

**Descartado** (já está no template base):
- `networking.hostName`, `time.timeZone`, `i18n.*`, `users.users.joao`, `system.stateVersion`, `imports`, header de função `{ config, pkgs, ... }:`, chaves externas

---

#### Módulo 1: `modules/system/systemd-boot.nix`
```nix
# NIXOS-LEGO-MODULE: systemd-boot
# PURPOSE: Systemd-boot UEFI bootloader configuration
# CATEGORY: system
# ---
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
```

#### Módulo 2: `modules/apps/gnome-desktop.nix`
```nix
# NIXOS-LEGO-MODULE: gnome-desktop
# PURPOSE: GNOME desktop environment with GDM display manager
# CATEGORY: apps
# ---
services.xserver.enable = true;
services.xserver.displayManager.gdm.enable = true;
services.xserver.desktopManager.gnome.enable = true;
```

#### Módulo 3: `modules/hardware/bluetooth.nix`
```nix
# NIXOS-LEGO-MODULE: bluetooth
# PURPOSE: Enable Bluetooth support
# CATEGORY: hardware
# ---
hardware.bluetooth.enable = true;
services.blueman.enable = true;
```

#### Módulo 4: `modules/hardware/pipewire-audio.nix`
```nix
# NIXOS-LEGO-MODULE: pipewire-audio
# PURPOSE: PipeWire audio server with PulseAudio and ALSA compatibility
# CATEGORY: hardware
# ---
sound.enable = true;
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
};
```

#### Módulo 5: `modules/apps/user-apps.nix`
```nix
# NIXOS-LEGO-MODULE: user-apps
# PURPOSE: Common desktop and development applications
# CATEGORY: apps
# ---
environment.systemPackages = with pkgs; [
  firefox
  git
  vim
  vscode
  htop
  wget
];
```

#### Módulo 6: `modules/services/ssh-server.nix`
```nix
# NIXOS-LEGO-MODULE: ssh-server
# PURPOSE: OpenSSH server configuration
# CATEGORY: services
# ---
services.openssh.enable = true;
```

---

## 9. Erros Fatais — O Que NUNCA Fazer

Para ser absolutamente claro, aqui está uma lista de erros que **quebrariam completamente** o sistema:

### ❌ ERRO 1: Incluir header de função
```nix
# NIXOS-LEGO-MODULE: exemplo
# PURPOSE: Exemplo
# CATEGORY: apps
# ---
{ pkgs, ... }:          # ← ERRADO! O builder já injeta este header
{
  environment.systemPackages = with pkgs; [ vim ];
}
```

### ❌ ERRO 2: Envolver o corpo em chaves
```nix
# NIXOS-LEGO-MODULE: exemplo
# PURPOSE: Exemplo
# CATEGORY: apps
# ---
{                        # ← ERRADO! O builder já injeta as chaves
  environment.systemPackages = with pkgs; [ vim ];
}                        # ← ERRADO!
```

### ❌ ERRO 3: Usar imports
```nix
# NIXOS-LEGO-MODULE: exemplo
# PURPOSE: Exemplo
# CATEGORY: system
# ---
imports = [ ./hardware-configuration.nix ];  # ← ERRADO! Sem imports
boot.loader.grub.enable = true;
```

### ❌ ERRO 4: Definir atributos reservados
```nix
# NIXOS-LEGO-MODULE: exemplo
# PURPOSE: Exemplo
# CATEGORY: system
# ---
networking.hostName = "meu-pc";    # ← ERRADO! Está no template base
system.stateVersion = "24.11";     # ← ERRADO! Está no template base
time.timeZone = "America/Sao_Paulo"; # ← ERRADO! Está no template base
```

### ❌ ERRO 5: Cabeçalho com mais ou menos de 4 linhas
```nix
# NIXOS-LEGO-MODULE: exemplo
# PURPOSE: Exemplo
# CATEGORY: apps
# AUTHOR: João            # ← ERRADO! 5ª linha no cabeçalho
# ---                      # ← O builder conta esta como linha 5, não como separador
environment.systemPackages = with pkgs; [ vim ];
```

### ❌ ERRO 6: Categoria inventada
```nix
# NIXOS-LEGO-MODULE: exemplo
# PURPOSE: Exemplo
# CATEGORY: desktop-environment  # ← ERRADO! Não existe esta categoria
# ---
```

---

## 10. Atributos que Permitem Merge Automático

O NixOS module system faz merge automático de certos tipos. Quando dois módulos definem o mesmo atributo, o comportamento é:

| Tipo de Atributo | Merge Automático? | Exemplo |
|-----------------|-------------------|---------|
| Listas | ✅ Sim — concatena | `environment.systemPackages`, `boot.kernelModules`, `users.users.<name>.extraGroups` |
| Attrsets aninhados | ✅ Sim — merge recursivo | `services.pipewire = { ... }` + `services.pipewire.jack.enable` |
| Booleanos | ⚠️ Conflito se ambos definem | Use `lib.mkDefault` ou `lib.mkForce` se necessário |
| Strings | ⚠️ Conflito se ambos definem | Use `lib.mkDefault` ou `lib.mkForce` se necessário |
| `nixpkgs.overlays` | ✅ Sim — concatena (é uma lista) | Pode ter overlays em módulos diferentes |

**Na prática:** Não tenha medo de ter `environment.systemPackages` em múltiplos módulos LEGO. O Nix vai fundir todas as listas automaticamente.

---

## 10.5. Flake Inputs e DevShells (`modules/overlays/flake-inputs.json` e `devshells.json`)

Quando um pacote **não existe no nixpkgs** (nem no `pkgs-master`), ele precisa vir de um flake externo. Para isso, use o arquivo `modules/overlays/flake-inputs.json`:

```json
[
  {
    "name": "zen-browser",
    "url": "github:youwen5/zen-browser-flake",
    "arg": "zen-browser-pkg",
    "attr": "packages.${system}.default",
    "follows_nixpkgs": false
  }
]
```

O builder gera automaticamente:
1. O `input` no flake
2. O argumento nos `outputs`
3. A entrada no `specialArgs`
4. O argumento no wrapper de cada módulo

**Para criar um módulo que usa um flake externo:**
```nix
# NIXOS-LEGO-MODULE: zen-browser
# PURPOSE: Zen Browser from youwen5/zen-browser-flake
# CATEGORY: apps
# ---
environment.systemPackages = [
  zen-browser-pkg
];
```

> **NOTA:** Não use `with pkgs;` para pacotes de flakes externos — referencie o arg diretamente.

**Fluxo para adicionar um novo flake:**
1. Adicione uma entrada em `modules/overlays/flake-inputs.json`
2. Crie o módulo LEGO referenciando o `arg`
3. Pronto — nenhuma edição em `nix.go` ou `base-flake.nix` necessária

Da mesma forma, ambientes puros de desenvolvimento (`devShells`) são declarados via `modules/overlays/devshells.json` e o go builder injeta-os. Módulos atômicos Nix NUNCA devem criar `devShells` baseados em mkShell manualmente.

---

## 11. Resumo Final para o Agente

Quando o usuário te pedir para converter, você deve:

1. **Ler** todo o conteúdo anexado
2. **Descartar** tudo que pertence ao template base (seção 7, passo 2)
3. **Agrupar** por funcionalidade coerente
4. **Classificar** em uma das 5 categorias
5. **Escrever** cada módulo com exatamente 4 linhas de cabeçalho + corpo Nix puro
6. **Informar** o caminho completo: `modules/<categoria>/<nome>.nix`
7. **Entregar** os módulos prontos para o usuário copiar/salvar

Se o usuário pedir "converta em 1 módulo", tente respeitar, mas **avise** se o conteúdo deveria ser dividido para manter a atomicidade.

Se o usuário pedir "converta em vários módulos", divida agressivamente por funcionalidade.

**LEMBRE-SE: O objetivo final é que qualquer pessoa — inclusive um iniciante em NixOS — consiga pegar essas peças LEGO e montar sua configuração sem saber nada de Nix modules, flakes ou a complexidade por trás. Cada peça deve ser autocontida, clara e funcional.**
