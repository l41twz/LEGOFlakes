# NIXOS-LEGO-MODULE: speaches-stt-tts-nvidia
# PURPOSE: Speaches STT/TTS server (OpenAI API compatible) on GTX 1070 Ti
# CATEGORY: services
# ---

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║          SPEACHES — STT + TTS na GTX 1070 Ti (compute-only)                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Servidor all-in-one de Speech-to-Text (faster-whisper) e Text-to-Speech
# (Kokoro/Piper) com API 100% compatível com OpenAI.
#
# Endpoints:
#   /v1/audio/transcriptions  → STT (Whisper)
#   /v1/audio/speech           → TTS (Kokoro)
#
# Pinado na GTX 1070 Ti (PCI 09:00.0) via NVIDIA_VISIBLE_DEVICES.
# Conectado à rede khoj-net para integração direta com o Khoj.
#
# Requer: docker-engine module, gpu-nvidia-pascal module, khoj module (para a rede khoj-net)

hardware.nvidia-container-toolkit.enable = true;

virtualisation.oci-containers.containers.speaches = {
  image = "ghcr.io/speaches-ai/speaches:latest-cuda-12.6.3";

  ports = [ "8000:8000" ];

  environment = {
    # ── GPU: usar EXCLUSIVAMENTE a GTX 1070 Ti ──
    # O mapeamento do CDI (--device=nvidia.com/gpu=0) já cuida do isolamento nativo.
    CUDA_DEVICE_ORDER = "PCI_BUS_ID";

    # ── Whisper (STT) ──
    WHISPER__INFERENCE_DEVICE = "cuda";
    # A placa GTX 1070 Ti (arquitetura Pascal) NÃO possui Tensor Cores. O motor CTranslate2 rejeita float16 nela.
    # Precisamos usar float32 (ou int8_float32) para funcionar!
    WHISPER__COMPUTE_TYPE = "float32";

    # ── TTL: descarregar modelos da VRAM após 5min sem uso ──
    STT_MODEL_TTL = "300";
    TTS_MODEL_TTL = "300";

    # ── Chat completions: conecta ao Ollama (na 1080 Ti) via rede Docker ──
    CHAT_COMPLETION_BASE_URL = "http://host.docker.internal:11435/v1";

    # ── Logging ──
    LOG_LEVEL = "info";
  };

  volumes = [
    "speaches_hf_cache:/home/ubuntu/.cache/huggingface/hub"
  ];

  extraOptions = [
    "--network=khoj-net"
    "--network-alias=speaches"
    "--device=nvidia.com/gpu=0"
    "--add-host=host.docker.internal:host-gateway"
    "--health-cmd=curl -f http://0.0.0.0:8000/health"
    "--health-interval=30s"
    "--health-timeout=10s"
    "--health-retries=3"
  ];
};

# Dependência: o container Speaches precisa da rede khoj-net criada pelo módulo Khoj
systemd.services.docker-speaches.after = [ "docker-network-khoj.service" ];
systemd.services.docker-speaches.requires = [ "docker-network-khoj.service" ];
