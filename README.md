# Claude Code Multi-Model Proxy

A seamless integration for **Claude Code** that allows you to easily switch between different LLM providers (NVIDIA NIM, Google Gemini, OpenAI GPT, Groq, DeepSeek, etc.) using a local LiteLLM proxy. It includes automated startup and graceful shutdown tied directly to your terminal lifecycle.

---

## 🚀 Features
- **Global Commands**: Use `claude` and `switch-model` from *any* folder or workspace.
- **Smart Proxy Management**: Auto-starts the LiteLLM proxy when you type `claude`. When you close your terminal or VS Code, the proxy dies with it. No lingering background processes!
- **Multi-Model Support**: Switch providers on-the-fly without manually editing configuration files.
- **Automatic Key Management**: Prompts you for API keys only if they are missing and saves them securely in `.env`.

---

## 💻 Global Commands
These commands can be executed from **any PowerShell terminal** on your machine.

### `claude`
The standard command to launch Claude Code. 
*What it does under the hood:*
1. Checks if the local proxy is running on port 4000.
2. If not, boots up the proxy using your active model configuration.
3. Launches the actual Claude CLI pointed to your local proxy.
4. If you exit Claude normally, it shuts down the proxy cleanly.

### `switch-model <model-name>`
Quickly swap the backend AI model powering Claude Code.
*Examples:*
- `switch-model gpt` - Switches to OpenAI GPT-4o
- `switch-model gemini` - Switches to Google Gemini 2.5 Flash
- `switch-model nvidia` - Switches to NVIDIA GLM-5.2 (Free tier)
- `switch-model groq` - Switches to Groq Llama 3.3 70B
- `switch-model deepseek` - Switches to DeepSeek Chat

---

## 📁 Repository Structure
- `models.json` - Registry of all available models and their LiteLLM routing configurations.
- `switch_model.ps1` - The script responsible for updating settings when you run the global `switch-model` command.
- `start_proxy.bat` - Backup script to manually start the LiteLLM proxy if automation fails.
- `litellm_config.yaml` - (Auto-generated) The routing config that LiteLLM reads.
- `.env` - (Ignored in Git) Where your private API keys are securely stored.

---

## 🛠️ How to Setup (For a New Machine or Teammate)

If you are cloning this repository to a new laptop, follow these steps to get everything working globally.

### 1. Prerequisites
Ensure you have the following installed:
1. **Python & pip** (to install LiteLLM)
2. **Node.js & npm** (to install Claude Code)

### 2. Install Dependencies
Open a terminal and install the required tools globally:
```powershell
pip install litellm
npm install -g @anthropic-ai/claude-code
```

### 3. Clone this Repository
Clone this repository to a permanent location (e.g., `C:\tools\ClaudeProxy`). 
*Note: Do not delete this folder later, as your PowerShell profile will link directly to it.*

### 4. Setup the PowerShell Profile
You need to add the global functions to your PowerShell Profile.
1. Open PowerShell and run: `notepad $PROFILE` (If the file doesn't exist, create it).
2. Copy the contents of the `claude` and `switch-model` functions into your profile.
3. **IMPORTANT:** Make sure you update the `$global:ClaudeConfigDir` variable in the profile to point to the exact path where you cloned this folder!
4. Save the file and restart your terminal.

### 5. Start Coding!
Just type `switch-model gpt` (or any other model) to get started. It will prompt you for your API key, save it to a `.env` file, and prepare the proxy. 

Next time you type `claude`, it will magically work using your chosen model!

---

## 🆘 Troubleshooting & Manual Backup

If the PowerShell automation ever fails or hangs, you can fall back to running things manually using the scripts in this folder:

1. **Start Proxy Manually**: Double-click `start_proxy.bat` or run it from the terminal. Keep that window open.
2. **Set Environment Variables**: In a separate terminal, manually set the Anthropic variables:
   ```powershell
   $env:ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
   $env:ANTHROPIC_API_KEY="sk-ant-api03-1234567890..." # Any placeholder key
   ```
3. **Run Claude**: `claude`

To kill a stuck proxy manually:
```powershell
Stop-Process -Name litellm -Force
```
