# Diretrizes para Criação de Módulos NixOS-LEGO

## REGRAS ABSOLUTAS

1. **NUNCA adicione headers de função** (`{ pkgs, lib, config, ... }:`)
   - Módulos são ZERO-HEADER — headers adicionados pelo concatenador

2. **SEMPRE inicie com EXATAMENTE 4 linhas comentadas:**
   ```nix
   # NIXOS-LEGO-MODULE: <nome-do-modulo>
   # PURPOSE: <descrição-curta-em-uma-linha>
   # CATEGORY: <categoria>
   # ---
   ```

3. **CATEGORIAS RESTRITAS (5 opções, sem exceções):**

   | Categoria | Quando usar | Exemplos |
   |-----------|-------------|----------|
   | `system` | Configurações base do SO | boot, kernel, swap, systemd |
   | `hardware` | Dispositivos físicos e drivers | bluetooth, GPU, audio, PipeWire |
   | `apps` | Aplicações de usuário | Firefox, Git, Vim, VSCode |
   | `services` | Daemons e serviços em background | SSH, Docker, Steam, Nginx |
   | `overlays` | Modificações de pacotes nixpkgs | patches, overrides, versões custom |

4. **APENAS código Nix puro** após o header — sem imports, sem módulos aninhados

5. **NUNCA defina** (já estão no template base):
   - `networking.hostName`
   - `system.stateVersion`
   - `users.users.<nome>`
   - Configurações de timezone e locale

6. **Prefira `with pkgs;`** para listar pacotes

7. **Validação obrigatória**: Todo módulo passa por `nix-instantiate --parse`

## CHECKLIST

- [ ] Header com EXATAMENTE 4 linhas comentadas?
- [ ] Categoria é UMA das 5 permitidas?
- [ ] Código é Nix puro (sem headers de função)?
- [ ] NÃO conflita com template base?
- [ ] Sintaxe Nix correta?

## EXEMPLO VÁLIDO

```nix
# NIXOS-LEGO-MODULE: pipewire-audio
# PURPOSE: Modern audio server with PulseAudio compatibility
# CATEGORY: hardware
# ---
security.rtkit.enable = true;
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = true;
};
```

## ERROS COMUNS

❌ Header de função:
```nix
{ pkgs, lib, config, ... }:
{ environment.systemPackages = with pkgs; [ vim ]; }
```

❌ Categoria inventada:
```nix
# CATEGORY: desktop-environment
```

❌ Conflito com template base:
```nix
networking.hostName = "meu-pc";
```
