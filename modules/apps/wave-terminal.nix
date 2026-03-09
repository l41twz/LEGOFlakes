# NIXOS-LEGO-MODULE: wave-terminal
# PURPOSE: Wave Terminal with Unstable Fish Shell and Fish-AI tab completions plugin
# CATEGORY: apps
# ---
environment.systemPackages = [
  # pkgs-master.waveterm <-- usa versão 0.13.1
  # Sobreposição manual para alcançar a versão exata v0.14.1 no Github
  (pkgs-master.waveterm.overrideAttrs (old: rec {
    version = "0.14.1";
    src = pkgs.fetchurl {
      url = "https://github.com/wavetermdev/waveterm/releases/download/v${version}/waveterm-linux-amd64-${version}.deb";
      sha256 = "0aiia7x7r5rw81gw4q57cpfprlhwrbpcxnpf633xzz1cqpjcwfgp";
    };
  }))
  
  # O fish-ai precisa vir do 'pkgs' local onde o overlay abaixo atua
  pkgs.fish-ai 
];

programs.fish = {
  enable = true;
  # Use the unstable version of Fish shell directly
  package = pkgs-master.fish;
};

# Fish-AI currently involves custom build as it's not natively in nixpkgs
nixpkgs.overlays = [
  (final: prev: {
    fish-ai = prev.fishPlugins.buildFishPlugin {
      pname = "fish-ai";
      version = "1.0.0-git";
      src = prev.fetchFromGitHub {
        owner = "Realiserad";
        repo = "fish-ai";
        rev = "e1762f05d30573a4d097cd09948e6e8196e68843";
        hash = "sha256-dkudvyuf/hYxXMtAwHIw2aQaftneBdZf1a+otU15FKY=";
      };
    };
  })
];

# In order to hook it correctly into fish
environment.etc."fish/conf.d/fish-ai.fish".text = ''
  # O plugin usa dependências locais que no Nix precisam estar integradas.
  # Adicionando-o aos caminhos do Fish System-wide
'';
