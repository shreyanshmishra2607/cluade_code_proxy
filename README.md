# Claude Code Multi-Model Proxy

Use **Claude Code** with any LLM provider — NVIDIA NIM, Google Gemini, OpenAI GPT, Groq, DeepSeek, Mistral — by routing traffic through a local [LiteLLM](https://github.com/BerriAI/litellm) proxy. Switch models from any folder, and the proxy starts/stops automatically with your terminal.

> **Note:** This does NOT hijack the `claude` command. The real `claude` CLI works normally. The proxy version uses `claudep` instead.

---

## ✨ Features

- **One-command install** — run `.\install.ps1` and you're done.
- **Global commands** — `claudep` and `switch-model` work from *any* folder.
- **Non-invasive** — the real `claude` command is untouched. Use `claude` for official API, `claudep` for proxy.
- **Auto proxy lifecycle** — the proxy boots when you run `claudep` and dies when you close the terminal.
- **On-the-fly model switching** — swap providers without editing config files.
- **Key management** — prompts for an API key only if it's missing, then saves it to `.env`.

---

## 📋 Available Models

| Command | Provider | Model | Free tier |
|---|---|---|---|
| `switch-model nvidia` | NVIDIA NIM | `z-ai/glm-5.2` | ✅ |
| `switch-model gemini` | Google Gemini | `gemini-2.5-flash` | ✅ |
| `switch-model groq` | Groq | `llama-3.3-70b-versatile` | ✅ |
| `switch-model deepseek` | DeepSeek | `deepseek-chat` | |
| `switch-model gpt` | OpenAI | `gpt-4o` | |
| `switch-model mistral` | Mistral | `mistral-large-latest` | |

---

## 🚀 Quick Start

### 1. Install Prerequisites
- **Python 3.10+** → [python.org](https://www.python.org/downloads/)
- **Node.js LTS** → [nodejs.org](https://nodejs.org/)

Then install the tools:
```powershell
pip install litellm
npm install -g @anthropic-ai/claude-code
```

### 2. Clone & Install

```powershell
git clone https://github.com/shreyanshmishra2607/cluade_code_proxy.git
cd cluade_code_proxy
.\install.ps1
```

The installer will:
- ✅ Check that `litellm` and `claude` are installed
- ✅ Register the folder path dynamically
- ✅ Walk you through picking a free model and pasting your API key
- ✅ Inject the global commands into your PowerShell profile

### 3. Start Coding

Close the terminal, open a new one, and type:
```powershell
claudep
```

That's it. 🎉

---

## 💻 Global Commands

These work from **any PowerShell terminal**, in any folder.

| Command | What it does |
|---|---|
| `claudep` | Auto-starts the proxy and launches Claude Code via proxy |
| `claude` | Runs the real Claude CLI directly (no proxy, official API) |
| `switch-model <name>` | Switches the active LLM provider (e.g., `switch-model gemini`) |
| `claudep-setup` | Re-registers the proxy folder if you moved it |

---

## 📁 Repository Structure

| File | Description |
|---|---|
| `install.ps1` | One-command installer for new users |
| `uninstall.ps1` | Clean removal of global commands |
| `models.json` | Registry of all models and their LiteLLM routing config |
| `switch_model.ps1` | Updates config when you run `switch-model` |
| `start_proxy.bat` | Manual fallback to start the proxy |
| `litellm_config.yaml` | **(Auto-generated)** Routing config for LiteLLM |
| `active_model.txt` | **(Auto-generated)** Currently selected model key |
| `.env` | **(Git-ignored)** Your private API keys |

---

## 🔄 Moving the Folder

If you move this folder to a new location, just `cd` into it and run:
```powershell
claudep-setup
```
Or re-run `.\install.ps1`. No manual path editing needed.

---

## 🗑️ Uninstall

```powershell
.\uninstall.ps1
```
Removes the global commands from your PowerShell profile. Your API keys in `.env` are untouched.

---

## 🆘 Troubleshooting

### Proxy won't start
```powershell
# Kill any stuck proxy
Stop-Process -Name litellm -Force

# Check logs
Get-Content proxy_stderr.log -Tail 20
```

### "switch-model is not recognized"
Your profile didn't reload. Close and reopen the terminal, or:
```powershell
. $PROFILE
```

### Manual fallback
If automation breaks, run things manually:
```powershell
# Terminal 1: Start proxy
.\start_proxy.bat

# Terminal 2: Connect Claude
$env:ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
$env:ANTHROPIC_API_KEY="sk-ant-api03-LOCAL-PROXY-PLACEHOLDER"
claude
```

---

## 🔧 How It Works

1. `install.ps1` saves this folder's path to `~/.claude_proxy_path` and injects functions into your PowerShell `$PROFILE`.
2. When you type `claudep`, the function reads the path from that pointer file, loads your `.env` keys, boots LiteLLM on port 4000, and launches Claude Code.
3. The proxy is attached to the terminal's console — when the terminal dies, the proxy dies. No orphaned processes.
4. `switch-model` reads `models.json`, rewrites `litellm_config.yaml`, and saves your choice to `active_model.txt`.
5. The real `claude` command is never touched — you can use it normally with an official Anthropic API key or Ollama.
