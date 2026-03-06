# NIXOS-LEGO-MODULE: khoj
# PURPOSE: Khoj AI assistant deployed via Docker container
# CATEGORY: services
# ---

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                  KHOJ — ASSISTENTE DE IA VIA DOCKER                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Tradução fiel do docker-compose.yml oficial do Khoj para NixOS oci-containers.
# https://github.com/khoj-ai/khoj/blob/master/docker-compose.yml
#
# Requer: docker-engine module

# ── Rede Docker compartilhada ──
# No docker-compose, todos os serviços compartilham uma rede bridge automaticamente.
# No NixOS precisamos criar essa rede manualmente para que os containers se
# encontrem por nome (database, sandbox, search, etc.).
systemd.services.docker-network-khoj = {
  description = "Create Docker network for Khoj stack";
  after = [ "docker.service" ];
  requires = [ "docker.service" ];
  before = [
    "docker-khoj-database.service"
    "docker-khoj-sandbox.service"
    "docker-khoj-search.service"
    "docker-khoj-computer.service"
    "docker-khoj-server.service"
  ];
  wantedBy = [ "multi-user.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };
  path = [ pkgs.docker ];
  script = ''
    docker network inspect khoj-net >/dev/null 2>&1 || docker network create khoj-net
  '';
};

virtualisation.oci-containers.backend = "docker";

virtualisation.oci-containers.containers = {

  # ── database ──
  khoj-database = {
    image = "docker.io/pgvector/pgvector:pg15";
    environment = {
      POSTGRES_USER = "postgres";
      POSTGRES_PASSWORD = "postgres";
      POSTGRES_DB = "khoj";
    };
    volumes = [ "khoj_db:/var/lib/postgresql/data/" ];
    extraOptions = [
      "--network=khoj-net"
      "--network-alias=database"
      "--health-cmd=pg_isready -U postgres"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=5"
    ];
  };

  # ── sandbox ──
  khoj-sandbox = {
    image = "ghcr.io/khoj-ai/terrarium:latest";
    extraOptions = [
      "--network=khoj-net"
      "--network-alias=sandbox"
      "--health-cmd=curl -f http://localhost:8080/health"
      "--health-interval=30s"
      "--health-timeout=10s"
      "--health-retries=2"
    ];
  };

  # ── search ──
  khoj-search = {
    image = "docker.io/searxng/searxng:latest";
    volumes = [ "khoj_search:/etc/searxng" ];
    environment = {
      SEARXNG_BASE_URL = "http://localhost:8080/";
    };
    extraOptions = [
      "--network=khoj-net"
      "--network-alias=search"
      "--dns=8.8.8.8"
      "--dns=1.1.1.1"
    ];
  };

  # ── computer ──
  khoj-computer = {
    image = "ghcr.io/khoj-ai/khoj-computer:latest";
    ports = [ "5900:5900" ];
    volumes = [ "khoj_computer:/home/operator" ];
    extraOptions = [
      "--network=khoj-net"
      "--network-alias=computer"
    ];
  };

  # ── server ──
  khoj-server = {
    image = "ghcr.io/khoj-ai/khoj:pre"; #latest (was 1.41.10) or pre (was 2.0.0 beta 26)
    dependsOn = [ "khoj-database" ];
    ports = [ "42110:42110" ];
    workdir = "/app";
    volumes = [
      "khoj_config:/root/.khoj/"
      "khoj_models:/root/.cache/torch/sentence_transformers"
      "khoj_models:/root/.cache/huggingface"
    ];
    environment = {
      POSTGRES_DB = "khoj";
      POSTGRES_USER = "postgres";
      POSTGRES_PASSWORD = "postgres";
      POSTGRES_HOST = "database";
      POSTGRES_PORT = "5432";
      KHOJ_DJANGO_SECRET_KEY = "secret";
      KHOJ_DEBUG = "False";
      KHOJ_ADMIN_EMAIL = "253585242+l41twz@users.noreply.github.com";
      KHOJ_ADMIN_PASSWORD = "postgres";
      KHOJ_TERRARIUM_URL = "http://sandbox:8080";
      KHOJ_SEARXNG_URL = "http://search:8080";
      KHOJ_TELEMETRY_DISABLE = "True";

      # Uncomment line below to have Khoj run code in remote E2B code sandbox instead of the self-hosted Terrarium sandbox above. Get your E2B API key from https://e2b.dev/.
      # E2B_API_KEY = "your_e2b_api_key";

      # Uncomment line below to use with Ollama running on your local machine at localhost:11434.
      # Change URL to use with other OpenAI API compatible providers like VLLM, LMStudio, DeepInfra, DeepSeek etc.
      OPENAI_BASE_URL = "http://host.docker.internal:11434/v1/";
      KHOJ_DEFAULT_CHAT_MODEL = "ministral-3:3b-instruct-2512-q4_K_M";
      #
      # Uncomment appropriate lines below to use chat models by OpenAI, Anthropic, Google.
      # Ensure you set your provider specific API keys.
      # ---
      # OPENAI_API_KEY = "your_openai_api_key";
      # GEMINI_API_KEY = "your_gemini_api_key";
      # ANTHROPIC_API_KEY = "your_anthropic_api_key";
      #
      # Uncomment line below to enable Khoj to use its computer.
      # KHOJ_OPERATOR_ENABLED = "True";
      #
      # Uncomment appropriate lines below to enable web results with Khoj
      # Ensure you set your provider specific API keys.
      # ---
      # Paid, Fast API. Only does web search. Get API key from https://serper.dev/
      # SERPER_DEV_API_KEY = "your_serper_dev_api_key";
      # Paid, Higher Read Success API. Only does webpage read. Get API key from https://olostep.com/
      # OLOSTEP_API_KEY = "your_olostep_api_key";
      # Paid, Open API. Does both web search and webpage read. Get API key from https://firecrawl.dev/
      # FIRECRAWL_API_KEY = "your_firecrawl_api_key";
      # Paid, Fast API. Does both web search and webpage read. Get API key from https://exa.ai/
      # EXA_API_KEY = "your_exa_api_key";
      #
      # Uncomment the necessary lines below to make your instance publicly accessible.
      # Proceed with caution, especially if you are using anonymous mode.
      # ---
      # KHOJ_NO_HTTPS = "True";
      # Replace the KHOJ_DOMAIN with the server's externally accessible domain or I.P address from a remote machie (no http/https prefix).
      # Ensure this is set correctly to avoid CSRF trusted origin or unset cookie issue when trying to access the admin panel.
      # KHOJ_DOMAIN = "192.168.0.104";
      # KHOJ_DOMAIN = "khoj.example.com";
      # Replace the KHOJ_ALLOWED_DOMAIN with the server's internally accessible domain or I.P address on the host machine (no http/https prefix).
      # Only set if using a load balancer/reverse_proxy in front of your Khoj server. If unset, it defaults to KHOJ_DOMAIN.
      # For example, if the load balancer service is added to the khoj docker network, set KHOJ_ALLOWED_DOMAIN to khoj's docker service name: `server'.
      # KHOJ_ALLOWED_DOMAIN = "server";
      # KHOJ_ALLOWED_DOMAIN = "127.0.0.1";
    };
    cmd = [ "--host=0.0.0.0" "--port=42110" "--anonymous-mode" "-vv" "--non-interactive" ]; #"--anonymous-mode" no mult-user and api key, local only use.
    extraOptions = [
      "--network=khoj-net"
      "--network-alias=server"
      "--add-host=host.docker.internal:host-gateway"
      "--dns=8.8.8.8"
      "--dns=1.1.1.1"
    ];
  };
};
