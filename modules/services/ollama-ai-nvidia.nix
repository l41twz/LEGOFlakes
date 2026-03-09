# NIXOS-LEGO-MODULE: ollama-ai-nvidia
# PURPOSE: Ollama local LLM server with CUDA acceleration for NVIDIA GPUs
# CATEGORY: services
# ---
services.ollama = {
  enable = true;

  # Aceleração nativa via CUDA para placas de vídeo NVIDIA
  acceleration = "cuda";

  port = 11434;
  host = "0.0.0.0"; # Permite comunicação via host gateway para contêineres Docker

  # Modelos para baixar automaticamente na primeira ativação
  loadModels = [
    "qwen3-coder-next"
  ];

  environmentVariables = {
    # Offload de todas as camadas do modelo para a VRAM da GPU 
    # (A 1080 Ti possui 11GB VRAM, suficiente para modelos de até ~13B dependendo da quantização)
    OLLAMA_GPU_LAYERS = "99";
    OLLAMA_KEEP_ALIVE = "5m";
  };
};

# Permitir que as redes bridge do Docker acessem o Ollama pela porta 11434 localmente
networking.firewall.interfaces."docker0".allowedTCPPorts = [ 11434 ];
networking.firewall.interfaces."br-+".allowedTCPPorts = [ 11434 ];

environment.systemPackages = with pkgs; [
  oterm # TUI nativa para conversar com modelos do Ollama pelo terminal
];
