# NIXOS-LEGO-MODULE: obsidian-khoj
# PURPOSE: Obsidian note-taking app with Khoj AI assistant for semantic search and chat
# CATEGORY: apps
# ---

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              OBSIDIAN + KHOJ — ASSISTENTE DE IA PARA SUAS NOTAS              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Este módulo instala o Obsidian (editor de notas Markdown) junto com o Khoj,
# um assistente de IA que transforma suas notas em uma base de conhecimento
# pesquisável com inteligência artificial.
#
# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ COMO O KHOJ FUNCIONA — Arquitetura                                          │
# ├─────────────────────────────────────────────────────────────────────────────┤
# │                                                                             │
# │  ┌──────────┐  Plugin    ┌──────────┐  API     ┌──────────┐                 │
# │  │ Obsidian │ ────────▶  │  Khoj    │ ───────▶ │  Ollama  │                 │
# │  │  (UI)    │            │  Server  │          │  (LLM)   │                 │
# │  │          │ ◀────────  │ :42110   │ ◀─────── │  :11434  │                 │
# │  └──────────┘  Resposta  └──────────┘  Texto   └──────────┘                 │
# │       │                       │                                             │
# │       │                       ▼                                             │
# │       │              ┌──────────────┐                                       │
# │       │              │  Embeddings  │  ← Representações vetoriais das       │
# │       └─────────────▶│   (DB local) │     suas notas para busca semântica   │
# │        Indexa notas  └──────────────┘                                       │
# │                                                                             │
# └─────────────────────────────────────────────────────────────────────────────┘
#
# ════════════════════════════════════════════════════════════════════════════════
# 📚 O QUE É BUSCA SEMÂNTICA E COMO EMBEDDINGS FUNCIONAM
# ════════════════════════════════════════════════════════════════════════════════
#
# 🔍 BUSCA TRADICIONAL vs BUSCA SEMÂNTICA
# ─────────────────────────────────────────
# Busca tradicional (Ctrl+F): Procura pela palavra EXATA.
#   → Pesquisar "feliz" NÃO encontra "alegre", "contente", "satisfeito".
#
# Busca semântica (Khoj): Procura pelo SIGNIFICADO.
#   → Pesquisar "feliz" ENCONTRA "alegre", "contente", "de bom humor".
#   → Pesquisar "como instalar NixOS" encontra suas notas sobre "configuração
#     do sistema operacional" mesmo que não contenham as palavras exatas.
#
# 🧬 O QUE SÃO EMBEDDINGS?
# ──────────────────────────
# Embeddings são representações numéricas (vetores) do significado de um texto.
# Imagine que cada frase vira uma coordenada num espaço multidimensional:
#
#   "O gato dormiu no sofá"     → [0.23, -0.45, 0.67, 0.12, ...]  (768 números)
#   "O felino descansou no móvel" → [0.21, -0.43, 0.65, 0.14, ...]  (parecido!)
#   "Python é uma linguagem"    → [0.89, 0.34, -0.22, 0.56, ...]  (diferente!)
#
# Frases com significado similar ficam "perto" neste espaço. O Khoj usa isso
# para encontrar notas relevantes mesmo quando as palavras são diferentes.
#
# Os modelos de embedding NÃO geram texto — apenas convertem texto em vetores.
# Por isso são muito pequenos e rápidos (nomic-embed-text tem só ~270MB).
#
# 🤖 COMO O KHOJ USA O OLLAMA
# ─────────────────────────────
# O Khoj precisa de DOIS tipos de modelo do Ollama:
#
#   1. Modelo de EMBEDDING (obrigatório para busca):
#      → Converte suas notas em vetores para busca semântica
#      → Recomendado: nomic-embed-text (já incluído no módulo ollama-ai)
#      → Alternativa leve: all-minilm (~23MB, menos preciso)
#
#   2. Modelo de CHAT (opcional, para assistente):
#      → Gera respostas em linguagem natural sobre suas notas
#      → Recomendado: qwen2.5:1.5b (rápido) ou qwen2.5:7b (melhor qualidade)
#      → O Khoj envia suas notas relevantes + sua pergunta ao modelo
#      → Isso se chama RAG (Retrieval Augmented Generation)
#
# 📖 O QUE É RAG (Retrieval Augmented Generation)?
# ──────────────────────────────────────────────────
# RAG é a técnica de buscar informações relevantes ANTES de perguntar ao LLM.
# Em vez de confiar apenas no "conhecimento" interno do modelo (que pode
# estar desatualizado ou inventar coisas), o RAG:
#
#   1. Recebe sua pergunta: "Qual foi minha receita de bolo?"
#   2. Busca notas relevantes via embeddings: encontra "receita-bolo.md"
#   3. Envia ao LLM: "Contexto: [conteúdo da nota]. Pergunta: [sua pergunta]"
#   4. O LLM responde baseado nas SUAS notas, não em dados aleatórios
#
# Isso reduz drasticamente as "alucinações" (respostas inventadas) do LLM!
#
# ════════════════════════════════════════════════════════════════════════════════
# 🔧 CONFIGURAÇÃO PÓS-INSTALAÇÃO (PASSO A PASSO)
# ════════════════════════════════════════════════════════════════════════════════
#
# Após ativar este módulo e fazer o rebuild do NixOS:
#
# PASSO 1 — Verificar que os serviços estão rodando:
#   $ systemctl status ollama    → Deve mostrar "active (running)"
#   $ systemctl status khoj      → Deve mostrar "active (running)"
#   $ curl http://localhost:11434 → Deve responder "Ollama is running"
#   $ curl http://localhost:42110 → Deve abrir a interface web do Khoj
#
# PASSO 2 — Configurar o Khoj (interface web):
#   Abra http://localhost:42110 no navegador
#   a) Crie uma conta local (email/senha — tudo fica no seu PC)
#   b) Vá em Settings → Chat Model:
#      - Model Type: Openai
#      - Name: qwen2.5:1.5b (ou o modelo que você baixou)
#      - API Base URL: http://localhost:11434/v1/
#      - Max Prompt Size: 2048 (ajuste conforme o modelo)
#   c) Vá em Settings → Search Model (para busca semântica):
#      - Embedding Model: nomic-embed-text
#      - API Base URL: http://localhost:11434/v1/
#   d) Vá em Settings → Content → Obsidian:
#      - Aponte para a pasta do seu Vault (~/.obsidian ou ~/Documents/Obsidian)
#      - Clique "Index" para criar os embeddings das suas notas
#
# PASSO 3 — Instalar o plugin Khoj no Obsidian:
#   a) Abra Obsidian → Settings (⚙️) → Community Plugins
#   b) Desative "Restricted Mode" (modo restrito) se estiver ativado
#   c) Clique "Browse" e pesquise "Khoj"
#   d) Instale o plugin "Khoj — AI Personal Assistant"
#   e) Configure o plugin:
#      - Khoj URL: http://localhost:42110
#      - Habilite "Auto-sync" para indexar notas automaticamente
#   f) Use: Ctrl+K para buscar, ou abra o painel lateral do Khoj para chat
#
# PASSO 4 — Testar:
#   No Obsidian, use Ctrl+K e digite uma pergunta sobre suas notas.
#   Ou abra o painel do Khoj e converse sobre o conteúdo do seu vault!
#
# ════════════════════════════════════════════════════════════════════════════════
# 💡 DICAS PARA A VEGA 8 COM KHOJ
# ════════════════════════════════════════════════════════════════════════════════
#
#   • Indexação inicial pode ser LENTA com muitas notas. Seja paciente.
#   • Use nomic-embed-text para embeddings (melhor que all-minilm).
#   • Para chat, qwen2.5:1.5b é rápido. Se quiser mais qualidade e puder
#     esperar mais, tente qwen2.5:7b.
#   • O Khoj mantém os embeddings em cache — após a primeira indexação,
#     buscas subsequentes são instantâneas.
#   • Se o Ollama ficar sem memória durante a indexação do Khoj, reduza
#     o OLLAMA_GPU_LAYERS no módulo ollama-ai ou use um modelo de embedding
#     menor.
#
# ════════════════════════════════════════════════════════════════════════════════

# --- Obsidian (editor de notas Markdown) ---
environment.systemPackages = with pkgs; [
  obsidian
  # Obsidian é um editor de notas Markdown com graph view, backlinks,
  # e um ecossistema enorme de plugins da comunidade.
  # Seus dados ficam 100% locais em arquivos .md (sem cloud obrigatório).
];
