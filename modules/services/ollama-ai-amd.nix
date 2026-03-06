# NIXOS-LEGO-MODULE: ollama-ai
# PURPOSE: Ollama local LLM inference server with ROCm acceleration for AMD GPUs
# CATEGORY: services
# ---

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                        OLLAMA — SERVIDOR LOCAL DE LLMs                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# O Ollama é um runtime para rodar Large Language Models (LLMs) localmente.
# Ele funciona como um "servidor de modelos" que expõe uma API REST compatível
# com o formato OpenAI, permitindo que qualquer app (Obsidian, VS Code, terminal)
# se conecte e use os modelos para gerar texto, código, traduzir, etc.
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ ARQUITETURA: Como o Ollama funciona                                         │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  ┌──────────┐     API REST     ┌──────────┐      GPU/CPU      ┌─────────┐   │
# │  │  Client  │ ──────────────▶  │  Ollama  │ ──────────────▶   │  Model  │   │
# │  │ (Khoj,   │  localhost:11434 │  Server  │   ROCm / CUDA     │ (GGUF)  │   │
# │  │  oterm)  │ ◀──────────────  │ (systemd)│ ◀──────────────   │         │   │
# │  └──────────┘    Resposta      └──────────┘    Inferência     └─────────┘   │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ════════════════════════════════════════════════════════════════════════════════
# 📚 GUIA PARA INICIANTES: O QUE SÃO LLMs E COMO ESCOLHER MODELOS
# ════════════════════════════════════════════════════════════════════════════════
#
# 🔤 O QUE SÃO PARÂMETROS?
# ─────────────────────────
# Um LLM é essencialmente uma rede neural com bilhões de "pesos" (parâmetros).
# Quanto mais parâmetros, mais "conhecimento" o modelo pode armazenar, mas
# também mais memória (VRAM) ele consome e mais lento ele roda.
#
#   • 1B-3B    → Modelos ultraleves. Bons para tarefas simples, autocompletar,
#                 classificação. Respostas rápidas mas limitadas.
#   • 7B       → Sweet spot para hardware modesto. Respostas razoáveis para
#                 chat, código simples, e resumos.
#   • 13B      → Notável salto de qualidade. Precisa de ~10GB+ VRAM.
#   • 30B-70B  → Qualidade profissional. Requer GPUs de datacenter (24-80GB).
#
# ⚖️ O QUE É QUANTIZAÇÃO?
# ─────────────────────────
# Quantização é o processo de reduzir a precisão dos pesos do modelo para
# economizar memória. Imagine que cada peso é um número decimal:
#
#   • F32 (32 bits) → Precisão total. 4 bytes por peso.
#   • F16 (16 bits) → Meia precisão. 2 bytes por peso. Qualidade quase igual.
#   • Q8_0 (8 bits) → 1 byte por peso. Perda mínima de qualidade.
#   • Q5_K_M (5 bits) → ~0.625 bytes. Bom balanço qualidade/tamanho.
#   • Q4_K_M (4 bits) → ~0.5 bytes. Popular para hardware limitado.
#   • Q3_K_M (3 bits) → ~0.375 bytes. Perda notável, mas ainda funcional.
#   • Q2_K   (2 bits) → ~0.25 bytes. Qualidade degradada significativamente.
#
# A nomenclatura "K_M" significa "K-quant Medium" — uma técnica que mantém
# camadas mais importantes em precisão maior. K_S = Small, K_L = Large.
#
# Regra geral: Q4_K_M é o "sweet spot" para a maioria dos usos.
#
# 📐 TABELA DE CONSUMO DE VRAM (estimativas para modelos comuns)
# ──────────────────────────────────────────────────────────────
#
#   Modelo             │ Quant   │ Tamanho │ VRAM (est.) │ Cabe na Vega 8?
#   ───────────────────┼─────────┼─────────┼─────────────┼─────────────────
#   qwen2.5:0.5b       │ Q4_K_M  │ ~0.4GB  │ ~1 GB       │ ✅ Sim, bem rápido
#   qwen2.5:1.5b       │ Q4_K_M  │ ~1.0GB  │ ~1.5 GB     │ ✅ Sim, rápido
#   llama3.2:1b        │ Q4_K_M  │ ~0.7GB  │ ~1.2 GB     │ ✅ Sim, rápido
#   llama3.2:3b        │ Q4_K_M  │ ~2.0GB  │ ~2.8 GB     │ ✅ Sim, ok
#   phi4-mini:3.8b     │ Q4_K_M  │ ~2.5GB  │ ~3.5 GB     │ ✅ Sim, ok
#   qwen2.5:7b         │ Q4_K_M  │ ~4.7GB  │ ~5.5 GB     │ ✅ Sim, lento
#   gemma3:4b          │ Q4_K_M  │ ~3.0GB  │ ~3.8 GB     │ ✅ Sim, ok
#   llama3.1:8b        │ Q4_K_M  │ ~4.9GB  │ ~5.8 GB     │ ⚠️ Justo, lento
#   mistral:7b         │ Q4_K_M  │ ~4.4GB  │ ~5.2 GB     │ ✅ Sim, lento
#   deepseek-r1:1.5b   │ Q4_K_M  │ ~1.1GB  │ ~1.7 GB     │ ✅ Sim, rápido
#   deepseek-r1:7b     │ Q4_K_M  │ ~4.7GB  │ ~5.5 GB     │ ✅ Sim, lento
#   deepseek-r1:8b     │ Q4_K_M  │ ~5.2GB  │ ~6.0 GB     │ ⚠️ Justo, lento
#   codegemma:2b       │ Q4_K_M  │ ~1.4GB  │ ~2.0 GB     │ ✅ Sim, rápido
#   codegemma:7b       │ Q4_K_M  │ ~5.0GB  │ ~5.8 GB     │ ⚠️ Justo, lento
#   nomic-embed-text   │ F16     │ ~0.3GB  │ ~0.5 GB     │ ✅ Sim (embedding)
#   all-minilm         │ F16     │ ~0.1GB  │ ~0.2 GB     │ ✅ Sim (embedding)
#   ───────────────────┼─────────┼─────────┼─────────────┼─────────────────
#   llama3.1:13b       │ Q4_K_M  │ ~8.0GB  │ ~9.5 GB     │ ❌ Não cabe
#   qwen2.5:14b        │ Q4_K_M  │ ~9.0GB  │ ~10 GB      │ ❌ Não cabe
#   llama3.1:70b       │ Q4_K_M  │ ~42GB   │ ~45 GB      │ ❌ Nem pensar
#
# 💡 NOTA: "VRAM estimada" = tamanho do modelo + overhead do runtime (~0.5-1GB).
# A Vega 8 usa memória RAM do sistema como VRAM (iGPU), então certifique-se
# de ter RAM livre suficiente (recomendo 16GB de RAM total no sistema).
#
# 🎯 ESPECIALIDADES DOS MODELOS — PARA QUE CADA UM FOI TREINADO
# ───────────────────────────────────────────────────────────────
#
# Chat/Conversação Geral:
#   • qwen2.5 — Excelente multilíngue (inclui português!). Bom em raciocínio.
#   • llama3.2 — Meta's modelo aberto. Bom para chat geral.
#   • gemma3  — Google. Compacto e eficiente, bom em instruções.
#   • phi4-mini — Microsoft. Surpreendentemente capaz para o tamanho.
#   • mistral — Francês, muito bom para seguir instruções.
#
# Raciocínio e Pensamento ("Reasoning"):
#   • deepseek-r1 — Especializado em "chain of thought". Mostra o raciocínio
#                    passo-a-passo antes de dar a resposta final. Excelente
#                    para matemática e lógica. Disponível em versões destiladas
#                    de 1.5B a 70B.
#   • qwen2.5     — Também bom em raciocínio, especialmente nas versões maiores.
#
# Código/Programação:
#   • codegemma — Treinado especificamente para gerar/completar código.
#                  Versão 2B é rápida para autocompletar; 7B para gerar funções.
#   • qwen2.5-coder — Versão especializada em código do Qwen.
#   • deepseek-coder — Especializado em programação multilingue.
#
# Embeddings (para busca semântica, não geram texto):
#   • nomic-embed-text — Popular para RAG. 768 dimensões. Bom para Khoj.
#   • all-minilm — Ultraleve (~23MB). Bom para uso rápido.
#
# 🔧 QUANTIZAÇÃO vs QUALIDADE — QUANDO USAR CADA UMA
# ────────────────────────────────────────────────────
#
#   Cenário                     │ Quantização Recomendada
#   ────────────────────────────┼────────────────────────
#   VRAM apertada, só testar    │ Q3_K_M ou Q4_0
#   Uso diário, equilíbrio      │ Q4_K_M (recomendado!)
#   Qualidade máxima possível   │ Q5_K_M ou Q6_K
#   Embeddings (busca)          │ F16 (são pequenos, não precisa quantizar)
#   Modelo < 3B                 │ Q8_0 ou F16 (já são pequenos)
#
# 🐧 NOTA SOBRE ROCm E VEGA 8
# ─────────────────────────────
# A Vega 8 é uma iGPU (integrada ao processador) da arquitetura GCN 5.0.
# O identificador ROCm desta GPU é "gfx900". O ROCm oficialmente suporta
# GPUs mais novas (RDNA), mas a Vega funciona com o override abaixo.
# A performance será limitada comparada a GPUs dedicadas, mas suficiente
# para modelos pequenos (até ~7B Q4).
#
# ⚡ DICAS DE PERFORMANCE PARA HARDWARE LIMITADO
# ───────────────────────────────────────────────
#   1. Prefira modelos menores com quantização Q4_K_M
#   2. Feche apps pesados antes de rodar modelos grandes
#   3. Use nomic-embed-text (não all-minilm) para melhor qualidade de busca
#   4. Modelos de 1.5B-3B são ideais para testes rápidos e aprendizado
#   5. O primeiro carregamento de um modelo é mais lento (carrega na VRAM)
#   6. Após carregado, as respostas subsequentes são mais rápidas
#   7. Use `ollama ps` para ver quais modelos estão carregados na memória
#   8. Use `ollama rm <modelo>` para liberar espaço em disco
#
# ════════════════════════════════════════════════════════════════════════════════

# --- Serviço Ollama ---
services.ollama = {
  enable = true;

  # Aceleração via ROCm (AMD GPU compute)
  # Alternativas: "cuda" (NVIDIA), "rocm" (AMD), null (CPU only)
  #package = pkgs.ollama-rocm;          # ← isso substitui o acceleration = "rocm";

  # Override necessário para Vega 8 (gfx900)
  # Sem isso, o ROCm não reconhece a iGPU como compatível.
  # Para outras GPUs AMD:
  #   - RX 580/570 (Polaris)   → "8.0.3"
  #   - Vega 56/64             → "9.0.0"
  #   - RX 5700 XT (Navi 10)   → "10.1.0"
  #   - RX 6700 XT (Navi 22)   → "10.3.1"
  #   - RX 7900 XTX (Navi 31)  → "11.0.0"
  #rocmOverrideGfx = "9.0.0";

  package = pkgs-master.ollama-vulkan;   # ← Vulkan é mais compatível com Vega 8

  # Porta padrão da API REST (não altere a menos que haja conflito)
  # Outros apps (Khoj, oterm, Open WebUI) usam esta porta por padrão
  port = 11434;
  host = "0.0.0.0"; # Modificado para "0.0.0.0" para que os contêineres Docker consigam se comunicar via host gateway

  # Modelos para baixar automaticamente na primeira ativação do serviço.
  # Isso pode demorar na primeira vez (downloads de vários GB).
  # Remova ou adicione modelos conforme sua necessidade e VRAM disponível!
  #
  # 💡 SOBRE QUANTIZAÇÃO:
  # Se você usar apenas "modelo:tamanho" (ex: "qwen2.5:1.5b"), o Ollama baixará a
  # quantização padrão (geralmente Q4_K_M). 
  # Para definir uma quantização específica, adicione a tag exata do site do Ollama.
  # Exemplo: "qwen2.5:1.5b-instruct-q8_0" (8-bit) ou "qwen2.5:1.5b-instruct-fp16"
  # https://ollama.com/library/qwen3.5/tags
  loadModels = [
    # ── Chat/Raciocínio (escolha UM para começar) ──
    #"qwen3.5:1.5b"          # ~1GB — Rápido, multilíngue, bom para aprender
    # "qwen2.5:7b"           # ~4.7GB — Melhor qualidade, mais lento
    # "llama3.2:3b"          # ~2GB — Bom equilíbrio para a Vega 8
    # "phi4-mini"            # ~2.5GB — Surpreendente para o tamanho
    # "deepseek-r1:1.5b"    # ~1.1GB — Mostra raciocínio passo-a-passo
    # "gemma3:4b"            # ~3GB — Compact Google model
    "qwen3.5:2b-q4_K_M"
    "ministral-3:3b-instruct-2512-q4_K_M"

    # ── Embeddings (para busca semântica no Khoj) ──
    "nomic-embed-text"       # ~274MB — Recomendado para RAG/Khoj
    # "all-minilm"           # ~23MB — Alternativa ultraleve
  ];

  # Variáveis de ambiente adicionais para tuning do Ollama
  environmentVariables = {
    # Número de camadas do modelo a offload para a GPU
    # "99" = todas as camadas na GPU (máxima aceleração)
    # Reduza se estiver ficando sem VRAM (ex: "20" para modelo parcial na GPU)
    OLLAMA_GPU_LAYERS = "99";

    # Tempo (em minutos) que um modelo fica carregado na VRAM sem uso
    # antes de ser descarregado automaticamente. "5m" é bom para VRAM limitada.
    OLLAMA_KEEP_ALIVE = "5m";

    # Desativa Flash Attention, que tem problemas de compatibilidade
    # com o Vulkan em GPUs integradas da AMD (como a Vega 8),
    # causando erro de "segmentation violation" (SIGSEGV)
    OLLAMA_FLASH_ATTENTION = "0";
  };
};

# Permitir que a rede bridge do Docker acesse o Ollama pela porta 11434
networking.firewall.interfaces."docker0".allowedTCPPorts = [ 11434 ];
networking.firewall.interfaces."br-+".allowedTCPPorts = [ 11434 ]; # "br-+" cobre todas as redes customizadas do Docker (br-*)

# --- Ferramentas CLI e TUI para interagir com o Ollama ---
environment.systemPackages = with pkgs; [
  oterm             # TUI elegante para conversar com modelos Ollama
  # Comandos úteis após instalar:
  #   ollama list              → Lista modelos baixados
  #   ollama pull qwen2.5:7b   → Baixa um modelo específico
  #   ollama run qwen2.5:1.5b  → Inicia chat interativo no terminal
  #   ollama ps                → Mostra modelos carregados na VRAM
  #   ollama show qwen2.5:1.5b → Mostra detalhes do modelo (quant, params, etc)
  #   ollama rm <modelo>       → Remove um modelo do disco
  #   oterm                    → Abre a TUI gráfica para chat
];
