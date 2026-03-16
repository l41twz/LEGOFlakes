# NIXOS-LEGO-MODULE: ollama-ai-nvidia
# PURPOSE: Ollama LLM server pinned to GTX 1080 Ti (compute-only) via CUDA
# CATEGORY: services
# ---
services.ollama = {
  enable = true;

  # Compila o binário do Ollama apontando explicitamente para a arquitetura cuda 6.1 (Pascal)
  # Usa pkgs-master para a versão mais recente e faz override adicionando apenas a "61"
  package = pkgs-master.ollama-cuda.override {
    cudaArches = [ "61" ];
  };

  # ***DEPRECADO*** Mantemos o override na service ativado caso suportado
  # acceleration = "cuda";

  port = 11434;
  host = "0.0.0.0"; # Permite comunicação via host gateway para contêineres Docker

  # Modelos para baixar automaticamente na primeira ativação
  loadModels = [
    #"qwen3-coder-next"
    #"hf.co/Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF:Q8_0"
    #"hf.co/Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    "ministral-3:3b-instruct-2512-q4_K_M"
  ];

  environmentVariables = {
    # Força o Ollama a usar EXCLUSIVAMENTE a GTX 1080 Ti (PCI 0a:00.0)
    # Com PCI_BUS_ID ordering: 1070 Ti (09:00.0) = device 0, 1080 Ti (0a:00.0) = device 1
    CUDA_DEVICE_ORDER = "PCI_BUS_ID";
    CUDA_VISIBLE_DEVICES = "1";

    # Offload de todas as camadas do modelo para a VRAM da GPU
    # (A 1080 Ti possui 11GB VRAM, suficiente para modelos de até ~13B dependendo da quantização)
    OLLAMA_GPU_LAYERS = "99";
    OLLAMA_KEEP_ALIVE = "5m";

    # Como a 1080 Ti está limpa de vídeo (Headless), podemos definir overhead como 0.
    OLLAMA_GPU_OVERHEAD = "0";
    
    # Funciona apenas com o Flash Attention ativado
    # Comprime as matrizes de contexto mental/atenção pela metade (importante para modelos de 9B+ caberem em 11GB sem vazar para a CPU Ryzen)
    # OLLAMA_KV_CACHE_TYPE = "q8_0";

    # A arquitetura Pascal (sm_61 da GTX 1080 Ti) não possui Tensor Cores reais para Flash Attention e costuma travar/congelar a inferência no segundo turno  
    OLLAMA_FLASH_ATTENTION = "0";
  };
};

# Permitir que as redes bridge do Docker acessem o Ollama pela porta 11434 localmente
networking.firewall.interfaces."docker0".allowedTCPPorts = [ 11434 ];
networking.firewall.interfaces."br-+".allowedTCPPorts = [ 11434 ];

environment.systemPackages = with pkgs; [
  oterm # TUI nativa para conversar com modelos do Ollama pelo terminal
];
