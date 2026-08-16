# Claude Code Multi-Model Proxy

Use **Claude Code** with any LLM provider — NVIDIA NIM, Google Gemini, OpenAI GPT, Groq, DeepSeek, Mistral — by routing traffic through a local [LiteLLM](https://github.com/BerriAI/litellm) proxy. Switch models instantly from any folder, no terminal restart needed.

> **Note:** This does NOT hijack the `claude` command. The real `claude` CLI works normally. The proxy version uses `claudep` instead.

---

## ✨ Features

- **One-command install** — run `.\install.ps1` and you're done.
- **Global commands** — `claudep`, `switch-model`, `proxy-on`, `proxy-off` work from *any* folder.
- **Non-invasive** — the real `claude` command is untouched.
- **Auto proxy lifecycle** — the proxy boots when you run `claudep` and dies when you close the terminal.
- **Instant model switching** — swap models without editing config files or restarting the terminal.
- **Custom model override** — pass any model ID directly (e.g. `switch-model gpt gpt-5.5-pro`).
- **VS Code extension support** — use the Claude Code VS Code GUI with your proxy via `proxy-on`.
- **Key management** — prompts for an API key only if it's missing, then saves it to `.env`.
- **List available models** — query your provider's API to see what models your key supports.

---

## 📋 Available Models

| Command | Provider | Default Model | Free tier |
|---|---|---|---|
| `switch-model nvidia` | NVIDIA NIM | `z-ai/glm-5.2` | ✅ |
| `switch-model gemini` | Google Gemini | `gemini-2.5-flash` | ✅ |
| `switch-model groq` | Groq | `llama-3.3-70b-versatile` | ✅ |
| `switch-model deepseek` | DeepSeek | `deepseek-chat` | |
| `switch-model gpt` | OpenAI | `gpt-4o` | |
| `switch-model mistral` | Mistral | `mistral-large-latest` | |

### 🔮 Using Custom Models

List all models available for your OpenAI API key:
```powershell
.\list_openai_models.ps1
```

Once you have a model ID, pass it as a second argument — **no restart needed**, takes effect immediately:
```powershell
switch-model gpt gpt-5.5-pro
switch-model gpt gpt-5.3-codex
switch-model gemini gemini-1.5-pro
```

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
| `claudep` | Auto-starts the proxy and launches Claude Code in terminal |
| `claude` | Runs the real Claude CLI directly (no proxy, official Anthropic API) |
| `switch-model <name> [model_id]` | Switches provider and optionally overrides model ID. Auto-reloads profile. |
| `proxy-on` | Enables proxy for the VS Code extension — click the Claude icon without login |
| `proxy-off` | Disables proxy for VS Code — extension goes back to real Claude login |
| `claudep-setup` | Re-registers the proxy folder if you moved it |

---

## 🖥️ VS Code Extension Support

The Claude Code VS Code extension can also use your proxy, so you can click the Claude icon without logging in.

### Setup (one time)

**1. Enable proxy mode:**
```powershell
proxy-on
```
This permanently saves the proxy env vars at user level so VS Code picks them up.

**2. Restart VS Code** (required once after `proxy-on`).

**3. Start the proxy in a terminal:**
```powershell
claudep
```

**4. Click the Claude icon in VS Code** — it connects automatically. ✅

> **Keep `claudep` running in a terminal while using VS Code.** The proxy must be alive for the extension to work.

### Switching between proxy and real Claude

```powershell
# Use proxy (free/custom models via LiteLLM)
proxy-on

# Use real Claude (Opus, official Anthropic API — requires login)
proxy-off
```
Restart VS Code after each switch to apply.

---

## 📁 Repository Structure

| File | Description |
|---|---|
| `install.ps1` | One-command installer for new users |
| `uninstall.ps1` | Clean removal of global commands |
| `models.json` | Registry of all providers and their LiteLLM routing config |
| `switch_model.ps1` | Updates config when you run `switch-model` |
| `list_openai_models.ps1` | Lists all models available for your OpenAI API key |
| `setup_autostart.ps1` | Optional: auto-start proxy on Windows login |
| `litellm_config.yaml` | **(Auto-generated)** Routing config for LiteLLM |
| `active_model.txt` | **(Auto-generated)** Currently selected provider key |
| `active_model_id.txt` | **(Auto-generated)** Currently active model ID |
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

### VS Code extension shows API error after `proxy-on`
The proxy isn't running. Start it first:
```powershell
claudep
```
Then try the extension again.

### Proxy won't start
```powershell
# Kill any stuck proxy
Stop-Process -Name litellm -Force

# Check logs
Get-Content proxy_stderr.log -Tail 20
```

### "switch-model is not recognized"
Your profile didn't load. Close and reopen the terminal, or run:
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
claudep
```

---

## 🔧 How It Works

1. `install.ps1` saves this folder's path to `~/.claude_proxy_path` and injects functions into your PowerShell `$PROFILE`.
2. When you type `claudep`, it reads the active model ID from `active_model_id.txt`, loads your `.env` keys, boots LiteLLM on port 4000, and launches Claude Code.
3. The proxy is attached to the terminal's console — when the terminal closes, the proxy stops. No orphaned processes.
4. `switch-model <name> [model_id]` rewrites `litellm_config.yaml` with your model + all Claude model name aliases, saves the model ID, sets user-level env vars, and auto-reloads your profile.
5. `proxy-on` / `proxy-off` toggle permanent user-level env vars so the VS Code extension knows where to route requests.
6. The real `claude` command is never touched — you can use it normally with an official Anthropic API key.

### ⚡ Proxy Boot Performance
The proxy takes ~12 seconds on first boot. If you run `claudep` again while the proxy is already up (port 4000 is occupied), it skips startup and launches Claude instantly. Keep a terminal with `claudep` running to keep the proxy warm.
