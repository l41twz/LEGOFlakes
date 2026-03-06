# NIXOS-LEGO-MODULE: kernel-cachyos
# PURPOSE: Use CachyOS kernel
# CATEGORY: system
# ---
#
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  CachyOS Kernel — kernel otimizado com patches do CachyOS                  ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║  O CachyOS aplica patches de performance no kernel Linux, incluindo:       ║
# ║  • BORE scheduler (melhor responsividade em desktop/gaming)                ║
# ║  • Otimizações de I/O, memória e latência                                  ║
# ║  • Opcionalmente: LTO (Link-Time Optimization) via Clang                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ── 1. Overlay do nix-cachyos-kernel (pinned para garantir binary cache) ────
# Este overlay é injetado via flake-inputs.json pela build do LEGOFlakes.
nixpkgs.overlays = [
  cachyos-kernel-overlays.pinned
];

# ── 2. Escolha do kernel ────────────────────────────────────────────────────
boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore;

#
# Variantes disponíveis (troque acima conforme necessidade):
#
#  ┌─────────────────────────────────────────────┬─────────────────────────────────────────────────┐
#  │ Variante                                    │ Descrição                                       │
#  ├─────────────────────────────────────────────┼─────────────────────────────────────────────────┤
#  │ linuxPackages-cachyos-latest                │ Último kernel estável com patches CachyOS       │
#  │ linuxPackages-cachyos-latest-lto            │ Idem + LTO (Clang) — mais otimizado             │
#  │ linuxPackages-cachyos-lts                   │ Kernel LTS (longa manutenção) com patches       │
#  │ linuxPackages-cachyos-lts-lto               │ LTS + LTO                                       │
#  │ linuxPackages-cachyos-rc                    │ Release candidate — bleeding edge                │
#  │ linuxPackages-cachyos-bore                  │ Kernel com BORE scheduler exclusivo              │
#  │ linuxPackages-cachyos-hardened              │ Kernel hardened com patches de segurança          │
#  │ linuxPackages-cachyos-server                │ Otimizado para cargas de servidor                │
#  └─────────────────────────────────────────────┴─────────────────────────────────────────────────┘
#
# Lista completa:  nix flake show github:xddxdd/nix-cachyos-kernel/release

# ── 3. Binary caches (evita compilar o kernel localmente) ───────────────────
#
#  O mantenedor roda Hydra CI e publica binários pré-compilados.
#  Com esses caches, o rebuild baixa o kernel pronto (~minutos, não horas).
#
nix.settings = {
  substituters = [
    "https://cache.nixos.org/"
    "https://attic.xuyh0120.win/lantian"
    "https://cache.garnix.io"
    "https://nix-community.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
};
