# NIXOS-LEGO-MODULE: llama-cpp-qwen-server
# PURPOSE: Run llama.cpp as OpenAI-compatible API server with Qwen3.5 distilled model, CUDA support, and custom model path
# CATEGORY: services
# ---
nixpkgs.overlays = [
  (final: prev: {
    llama-cpp = (prev.llama-cpp.override { 
      cudaSupport = true; 
    }).overrideAttrs (oldAttrs: {
      cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [ 
        "-DCMAKE_CUDA_ARCHITECTURES=61" 
      ];
    });
  })
];

# 1. Garante que o binário fique disponível no terminal para o seu usuário
environment.systemPackages = [ pkgs.llama-cpp ];

  # 2. Configuração do Serviço
  systemd.services.llama-cpp-qwen-server = {
    enable = true;
    description = "llama.cpp OpenAI API server with Qwen3.5 Claude distilled model";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    preStart = ''
      mkdir -p /home/l41twz/ai-models/
      if [ ! -f /home/l41twz/ai-models/Qwen3.5-9B.Q8_0.gguf ]; then
        ${pkgs.wget}/bin/wget "https://huggingface.co/Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-GGUF/resolve/main/Qwen3.5-9B.Q8_0.gguf" -O /home/l41twz/ai-models/Qwen3.5-9B.Q8_0.gguf
      fi
      chown l41twz:users /home/l41twz/ai-models/Qwen3.5-9B.Q8_0.gguf
    '';
    
    serviceConfig = {
      ExecStart = ''
        ${pkgs.llama-cpp}/bin/llama-server \
          -m /home/l41twz/ai-models/Qwen3.5-9B.Q8_0.gguf \
          --host 0.0.0.0 \
          --port 11435 \
          --n-gpu-layers 33 \
          --ctx-size 32768 \
          --parallel 2 \
          --batch-size 512 \
          --alias qwen \
          --cache-type-k q8_0 \
          --cache-type-v q8_0 \
          --flash-attn auto
      '';
      Restart = "always";
      TimeoutStartSec = "infinity";
      User = "l41twz";
      Environment = [
        "CUDA_DEVICE_ORDER=PCI_BUS_ID"
        "CUDA_VISIBLE_DEVICES=1"
      ];
    };
  };

  # 3. Configuração do Serviço 4B na GTX 1070 Ti (DEVICE 0) multi-modal
  systemd.services.llama-cpp-qwen-4b-server = {
    enable = true;
    description = "llama.cpp OpenAI API server with Qwen3.5 4B Uncensored HauhauCS Aggressive";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    preStart = ''
      mkdir -p /home/l41twz/ai-models/
      if [ ! -f /home/l41twz/ai-models/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf ]; then
        ${pkgs.wget}/bin/wget "https://huggingface.co/HauhauCS/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf" -O /home/l41twz/ai-models/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf
      fi
      if [ ! -f /home/l41twz/ai-models/mmproj-Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-BF16.gguf ]; then
        ${pkgs.wget}/bin/wget "https://huggingface.co/HauhauCS/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive/resolve/main/mmproj-Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-BF16.gguf" -O /home/l41twz/ai-models/mmproj-Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-BF16.gguf
      fi
      chown l41twz:users /home/l41twz/ai-models/Qwen3.5-4B-Uncensored* || true
      chown l41twz:users /home/l41twz/ai-models/mmproj-Qwen3.5-4B* || true
    '';
    
    serviceConfig = {
      ExecStart = ''
        ${pkgs.llama-cpp}/bin/llama-server \
          -m /home/l41twz/ai-models/Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf \
          --mmproj /home/l41twz/ai-models/mmproj-Qwen3.5-4B-Uncensored-HauhauCS-Aggressive-BF16.gguf \
          --host 0.0.0.0 \
          --port 11436 \
          --n-gpu-layers 33 \
          --ctx-size 131072 \
          --parallel 2 \
          --batch-size 512 \
          --alias qwen-4b \
          --cache-type-k q4_0 \
          --cache-type-v q4_0 \
          --flash-attn auto
      '';
      Restart = "always";
      TimeoutStartSec = "infinity";
      User = "l41twz";
      Environment = [
        "CUDA_DEVICE_ORDER=PCI_BUS_ID"
        "CUDA_VISIBLE_DEVICES=0"
      ];
    };
    # essas variaveis abaixo sao usadas para reduzir o uso de vram deixando o contexto menor
    #      --cache-type-k q8_0 \
    #      --cache-type-v q8_0 \
      };

# Permitir que as redes bridge do Docker acessem o servidor pela porta 11435 e 11436 localmente
networking.firewall.interfaces."docker0".allowedTCPPorts = [ 11435 11436 ];
networking.firewall.interfaces."br-+".allowedTCPPorts = [ 11435 11436 ];
