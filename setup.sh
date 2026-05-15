#!/usr/bin/env bash
set -euo pipefail

log() { printf "[setup] %s\n" "$*"; }

append_line_if_missing() {
  local line="$1"
  local file="$2"
  touch "$file"
  grep -Fqx "$line" "$file" || printf "%s\n" "$line" >> "$file"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf "Missing required command: %s\n" "$1" >&2
    exit 1
  }
}

for cmd in curl tar git; do
  need_cmd "$cmd"
done

mkdir -p "$HOME/.local/bin" "$HOME/.local/opt" "$HOME/.config" "$HOME/.cache"

# -----------------------------
# Go setup
# -----------------------------
GO_VERSION="1.23.3"  # Updated to newer version
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"
GO_ROOT="$HOME/go"

if [ ! -x "$GO_ROOT/bin/go" ]; then
  log "Installing Go ${GO_VERSION}"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  curl -fsSL "$GO_URL" -o "$tmpdir/$GO_TARBALL"
  tar -xzf "$tmpdir/$GO_TARBALL" -C "$HOME"
else
  log "Go already installed: $($GO_ROOT/bin/go version 2>/dev/null || true)"
fi

append_line_if_missing 'export PATH="$HOME/go/bin:$PATH"' "$HOME/.zshrc"
append_line_if_missing 'export PATH="$HOME/go/bin:$PATH"' "$HOME/.bashrc"
export PATH="$HOME/go/bin:$PATH"

# Optional workspace
if [ ! -d "$HOME/piscine" ]; then
  mkdir -p "$HOME/piscine"
  (
    cd "$HOME/piscine"
    "$GO_ROOT/bin/go" mod init piscine >/dev/null 2>&1 || true
    "$GO_ROOT/bin/go" get github.com/01-edu/z01 >/dev/null 2>&1 || true
  )
fi

# -----------------------------
# Git identity
# -----------------------------
git config --global user.email "zmarrouhoussam@email.com"
git config --global user.name "hzmarrou"
git config --global credential.helper store

# -----------------------------
# Kitty
# -----------------------------
if [ ! -x "$HOME/.local/kitty.app/bin/kitty" ]; then
  log "Installing Kitty"
  curl -fsSL https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
fi

append_line_if_missing 'export PATH="$HOME/.local/kitty.app/bin:$PATH"' "$HOME/.zshrc"
append_line_if_missing 'export PATH="$HOME/.local/kitty.app/bin:$PATH"' "$HOME/.bashrc"
export PATH="$HOME/.local/kitty.app/bin:$PATH"

mkdir -p "$HOME/.config/kitty"
cat > "$HOME/.config/kitty/kitty.conf" <<'KCONF'
foreground #ffe164
background #1e1e1e
background_opacity 0.5
cursor #ffffff
selection_foreground #000000
selection_background #ffff00
KCONF

if command -v kitty >/dev/null 2>&1; then
  kitty @ set-colors --all "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
fi

# -----------------------------
# Brave AppImage
# -----------------------------
BRAVE_DIR="$HOME/brave-browser"
APPIMAGE_URL="https://github.com/srevinsaju/Brave-AppImage/releases/download/v1.88.7/Brave-nightly-v1.88.7-x86_64.AppImage"
APPIMAGE_FILE="$BRAVE_DIR/brave-nightly.AppImage"

mkdir -p "$BRAVE_DIR"
if [ ! -f "$APPIMAGE_FILE" ]; then
  log "Downloading Brave AppImage"
  curl -fsSL -o "$APPIMAGE_FILE" "$APPIMAGE_URL"
  chmod +x "$APPIMAGE_FILE"
fi

append_line_if_missing 'export PATH="$HOME/brave-browser:$PATH"' "$HOME/.zshrc"
append_line_if_missing 'export PATH="$HOME/brave-browser:$PATH"' "$HOME/.bashrc"

# -----------------------------
# GNOME keybindings
# -----------------------------
if command -v gsettings >/dev/null 2>&1; then
  log "Setting GNOME keybindings"
  CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM_PATH']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH name "BraveBrowser" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH command "$APPIMAGE_FILE" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH binding "<Control>b" || true

  gsettings set org.gnome.desktop.default-applications.terminal exec "$HOME/.local/kitty.app/bin/kitty" || true
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg "" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>Return']" || true

  # Other keybindings...
  gsettings set org.gnome.desktop.wm.keybindings minimize "['<Ctrl>m']" || true
  gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']" || true
  gsettings set org.gnome.desktop.wm.keybindings close "['<Ctrl>q']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']" || true
fi

# -----------------------------
# Neovim (updated to latest stable)
# -----------------------------
NVIM_VERSION="v0.12.2"
NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_TARBALL}"

if ! command -v nvim >/dev/null 2>&1; then
  log "Installing Neovim ${NVIM_VERSION}"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  curl -fsSL "$NVIM_URL" -o "$tmpdir/$NVIM_TARBALL"
  tar -xzf "$tmpdir/$NVIM_TARBALL" -C "$tmpdir"
  rm -rf "$HOME/.local/opt/nvim-linux-x86_64"
  mv "$tmpdir/nvim-linux-x86_64" "$HOME/.local/opt/"
  ln -sf "$HOME/.local/opt/nvim-linux-x86_64/bin/nvim" "$HOME/.local/bin/nvim"
  export PATH="$HOME/.local/bin:$PATH"
else
  log "Neovim already installed: $(nvim --version | head -n 1)"
fi

append_line_if_missing 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"
append_line_if_missing 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc"

# -----------------------------
# NvChad Setup
# -----------------------------
stamp="$(date +%Y%m%d-%H%M%S)"
if [ -d "$HOME/.config/nvim" ] && [ "$(find "$HOME/.config/nvim" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)" -gt 0 ]; then
  backup="$HOME/.config/nvim.backup-${stamp}"
  log "Backing up existing config to $backup"
  cp -a "$HOME/.config/nvim" "$backup"
fi

mkdir -p "$HOME/.config/nvim/lua/configs" "$HOME/.config/nvim/lua/plugins"

# init.lua
cat > "$HOME/.config/nvim/init.lua" <<'LUA'
vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"
require("lazy").setup({
  { "NvChad/NvChad", lazy = false, branch = "v2.5", import = "nvchad.plugins" },
  { import = "plugins" },
}, lazy_config)

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"
vim.schedule(function() require "mappings" end)
require "nvchad.autocmds"
LUA

# Missing file - this was the main problem
cat > "$HOME/.config/nvim/lua/configs/lazy.lua" <<'LAZY'
return {
  defaults = { lazy = true },
  install = { colorscheme = { "nvchad" } },
  ui = {
    border = "rounded",
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      pending = "",
    },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin", "tohtml", "getscript", "getscriptPlugin", "gzip",
        "logipat", "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
        "matchit", "tar", "tarPlugin", "rrhelper", "spellfile_plugin",
        "vimball", "vimballPlugin", "zip", "zipPlugin", "tutor", "rplugin",
      },
    },
  },
}
LAZY

# Rest of your config files (kept almost the same)
cat > "$HOME/.config/nvim/lua/autocmds.lua" <<'LUA'
require "nvchad.autocmds"
LUA

cat > "$HOME/.config/nvim/lua/chadrc.lua" <<'LUA'
---@type ChadrcConfig
local M = {}
M.base46 = { theme = "gatekeeper" }
return M
LUA

cat > "$HOME/.config/nvim/lua/mappings.lua" <<'LUA'
require "nvchad.mappings"
local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
LUA

cat > "$HOME/.config/nvim/lua/options.lua" <<'LUA'
require "nvchad.options"
LUA

cat > "$HOME/.config/nvim/lua/configs/conform.lua" <<'LUA'
local options = {
  formatters_by_ft = {
    lua = { "stylua" },
  },
}
return options
LUA

cat > "$HOME/.config/nvim/lua/configs/lspconfig.lua" <<'LUA'
require("nvchad.configs.lspconfig").defaults()

vim.diagnostic.config({
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  virtual_text = { spacing = 2, source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

vim.lsp.enable({ "html", "cssls", "ts_ls", "gopls" })
LUA

cat > "$HOME/.config/nvim/lua/plugins/init.lua" <<'LUA'
return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    end,
  },

  {
    "pocco81/auto-save.nvim",
    lazy = false,
    config = function()
      require("auto-save").setup({ enabled = false })
      vim.keymap.set({ "i", "n", "v" }, "<Esc>", function()
        if vim.fn.mode() == "i" then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
        end
        pcall(vim.cmd, "silent! update")
      end, { noremap = true, silent = true })
    end,
  },

  {
    "stevearc/conform.nvim",
    lazy = false,
    config = function()
      require("conform").setup {
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
        formatters_by_ft = {
          go = { "gofmt" }, lua = { "stylua" }, python = { "black" }, c = { "clang_format" },
        },
      }
      vim.keymap.set("n", "<leader>f", function() require("conform").format() end, { desc = "Format file" })
    end,
  },

  -- Add your other plugins here...
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    config = function() vim.g.mkdp_auto_start = 1 end,
  },
}
LUA

# Optional: npm for typescript-language-server
if command -v npm >/dev/null 2>&1; then
  mkdir -p "$HOME/.local"
  npm config set prefix "$HOME/.local" >/dev/null 2>&1 || true
  if [ ! -x "$HOME/.local/bin/typescript-language-server" ]; then
    log "Installing typescript-language-server"
    npm install -g typescript typescript-language-server >/dev/null 2>&1 || true
  fi
fi

log "Syncing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

log "=== Setup Complete ==="
log "Run these commands now:"
log "  source ~/.zshrc"
log "  nvim"
log "Inside Neovim, run: :MasonInstall gopls html-lsp css-lsp lua-language-server stylua"
