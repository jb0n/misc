#!/usr/bin/env bash

# third-party agents + api keys: installs omp (oh-my-pi) and kilocode,
# then wires any api keys you pass into their configs. run from a repo
# checkout or standalone:

#   setup.sh --deepseek-apikey=$DEEPSEEK_API_KEY

set -euo pipefail

DEEPSEEK_API_KEY=""

usage() {
    cat <<'EOF'
usage: setup.sh [--deepseek-apikey=KEY]

options:
  --deepseek-apikey=KEY   DeepSeek API key. written to kilocode's config
                          (~/.config/kilo/kilo.json[c]) and to omp as a
                          custom provider (~/.omp/agent/models.yml, plus
                          modelRoles.default in config.yml) -- the same
                          shape as the machine this repo was scraped from.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --deepseek-apikey=*) DEEPSEEK_API_KEY="${1#*=}" ;;
        --deepseek-apikey) shift; DEEPSEEK_API_KEY="${1:-}" ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 1 ;;
    esac
    shift
done

#---------------------------------------------------------------------
# omp (oh-my-pi)
#---------------------------------------------------------------------
install_omp() {
    if command -v omp >/dev/null 2>&1; then
        echo "omp already installed: $(omp --version 2>/dev/null | head -1 || true)"
    else
        echo "installing omp (oh-my-pi)..."
        curl -fsSL https://omp.sh/install | sh
    fi
}

#---------------------------------------------------------------------
# kilocode
#---------------------------------------------------------------------
install_kilocode() {
    if command -v kilo >/dev/null 2>&1; then
        echo "kilocode already installed: $(kilo --version 2>/dev/null | head -1 || true)"
        return
    fi
    echo "installing kilocode (npm install -g @kilocode/cli)..."
    if ! npm install -g @kilocode/cli; then
        echo "plain npm install failed, retrying with sudo..."
        sudo npm install -g @kilocode/cli
    fi
}

#---------------------------------------------------------------------
# deepseek key -> omp: custom provider in ~/.omp/agent/models.yml
# (scraped from the machine this repo was born on) + default model role
#---------------------------------------------------------------------
configure_omp_deepseek() {
    local agent_dir="$HOME/.omp/agent"
    local models="$agent_dir/models.yml"
    local config="$agent_dir/config.yml"
    mkdir -p "$agent_dir"

    if [ -f "$models" ]; then
        cp "$models" "$models.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cat > "$models" <<YAML
providers:
  deepseek:
    baseUrl: https://api.deepseek.com
    api: openai-completions
    apiKey: $DEEPSEEK_API_KEY
    authHeader: true
    models:
      - id: deepseek-v4-pro
        name: DeepSeek V4 Pro
        reasoning: true
        thinking:
          minLevel: high
          maxLevel: xhigh
          mode: effort
        input: [text]
        contextWindow: 1000000
        maxTokens: 384000
        compat:
          supportsDeveloperRole: false
          supportsReasoningEffort: true
          maxTokensField: max_tokens
          reasoningEffortMap:
            high: high
            xhigh: max
          supportsToolChoice: false
          requiresReasoningContentForToolCalls: true
          requiresAssistantContentForToolCalls: true
          extraBody:
            thinking:
              type: enabled
      - id: deepseek-v4-flash
        name: DeepSeek V4 Flash
        reasoning: true
        thinking:
          minLevel: high
          maxLevel: xhigh
          mode: effort
        input: [text]
        contextWindow: 1000000
        maxTokens: 384000
        compat:
          supportsDeveloperRole: false
          supportsReasoningEffort: true
          maxTokensField: max_tokens
          reasoningEffortMap:
            high: high
            xhigh: max
          supportsToolChoice: false
          requiresReasoningContentForToolCalls: true
          requiresAssistantContentForToolCalls: true
          extraBody:
            thinking:
              type: enabled
YAML
    chmod 600 "$models"
    echo "omp: deepseek provider written to $models"

    if [ -f "$config" ] && grep -q 'modelRoles' "$config"; then
        echo "omp: $config already has modelRoles, leaving it alone"
    else
        printf 'modelRoles:\n  default: deepseek/deepseek-v4-flash\n' >> "$config"
        echo "omp: default model role set in $config"
    fi
}

#---------------------------------------------------------------------
# deepseek key -> kilocode: merge into ~/.config/kilo/kilo.json[c]
# (node is present because this script just installed kilocode via npm)
#---------------------------------------------------------------------
configure_kilocode_deepseek() {
    local dir="$HOME/.config/kilo" cfg
    mkdir -p "$dir"
    if [ -f "$dir/kilo.json" ]; then cfg="$dir/kilo.json"
    elif [ -f "$dir/kilo.jsonc" ]; then cfg="$dir/kilo.jsonc"
    else cfg="$dir/kilo.json"; fi

    if [ -f "$cfg" ]; then
        cp "$cfg" "$cfg.bak.$(date +%Y%m%d%H%M%S)"
    fi

    DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" node -e '
        const fs = require("fs");
        const file = process.argv[1];
        const key = process.env.DEEPSEEK_API_KEY;
        let cfg = {};
        try { cfg = JSON.parse(fs.readFileSync(file, "utf8")); } catch (e) { cfg = {}; }
        cfg.provider = cfg.provider || {};
        cfg.provider.deepseek = cfg.provider.deepseek || {};
        cfg.provider.deepseek.options = cfg.provider.deepseek.options || {};
        cfg.provider.deepseek.options.apiKey = key;
        cfg.provider.deepseek.options.baseURL = cfg.provider.deepseek.options.baseURL || "https://api.deepseek.com/v1";
        if (!cfg.model) cfg.model = "deepseek/deepseek-v4-flash";
        fs.writeFileSync(file, JSON.stringify(cfg, null, 2) + "\n");
    ' "$cfg"
    echo "kilocode: deepseek key written to $cfg"
}

install_omp
install_kilocode

if [ -n "$DEEPSEEK_API_KEY" ]; then
    configure_omp_deepseek
    configure_kilocode_deepseek
else
    echo "no api keys given; skipping key config (use --deepseek-apikey=KEY)"
fi

echo "ok, all set"
