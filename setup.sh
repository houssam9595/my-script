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
# Go setup (no sudo)
# -----------------------------
GO_VERSION="1.21.5"
GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TARBALL}"
GO_ROOT="$HOME/go"

if [ ! -x "$GO_ROOT/bin/go" ]; then
  log "Installing Go ${GO_VERSION} in $GO_ROOT"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  curl -fsSL "$GO_URL" -o "$tmpdir/$GO_TARBALL"
  tar -xzf "$tmpdir/$GO_TARBALL" -C "$HOME"
else
  log "Go already installed: $($GO_ROOT/bin/go version 2>/dev/null || true)"
fi

append_line_if_missing 'export PATH="$PATH:$HOME/go/bin"' "$HOME/.zshrc"
append_line_if_missing 'export PATH="$PATH:$HOME/go/bin"' "$HOME/.bashrc"
export PATH="$PATH:$HOME/go/bin"

# Optional workspace bootstrap (keeps old behavior, but safe)
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
# Kitty setup (no sudo)
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
# GNOME keybindings (if available)
# -----------------------------
if command -v gsettings >/dev/null 2>&1; then
  CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM_PATH']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH name "BraveBrowser" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH command "$APPIMAGE_FILE" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH binding "<Control>b" || true

  gsettings set org.gnome.desktop.default-applications.terminal exec "$HOME/.local/kitty.app/bin/kitty" || true
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg "" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>Return']" || true

  gsettings set org.gnome.desktop.wm.keybindings minimize "['<Ctrl>m']" || true
  gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']" || true
  gsettings set org.gnome.desktop.wm.keybindings close "['<Ctrl>q']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Ctrl>Left']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Ctrl>Right']" || true
  gsettings set org.gnome.shell.keybindings toggle-dash "['<Super>d']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.screenshot "['<Print>']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.area-screenshot "['<Ctrl><Shift>s']" || true
  gsettings set org.gnome.desktop.screensaver lock "['<Super>l']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.logout "['<Super><Shift>q']" || true
  gsettings set org.gnome.settings-daemon.plugins.media-keys.preferences "['<Super>e']" || true

  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Ctrl>Up']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Ctrl>Down']" || true
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Shift><Ctrl><Alt>Up']" || true
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Shift><Ctrl><Alt>Down']" || true

  for i in 1 2 3 4 5 6 7 8 9; do
    gsettings set org.gnome.desktop.wm.keybindings "switch-to-workspace-${i}" "['<Ctrl>${i}']" || true
    gsettings set org.gnome.desktop.wm.keybindings "move-to-workspace-${i}" "['<Shift><Ctrl>${i}']" || true
  done
fi

# -----------------------------
# Neovim setup (no sudo)
# -----------------------------
NVIM_VERSION="v0.11.6"
NVIM_TARBALL="nvim-linux-x86_64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_TARBALL}"

if ! command -v nvim >/dev/null 2>&1; then
  log "Installing Neovim ${NVIM_VERSION} to ~/.local/opt"
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

stamp="$(date +%Y%m%d-%H%M%S)"
if [ -d "$HOME/.config/nvim" ] && [ "$(find "$HOME/.config/nvim" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)" -gt 0 ]; then
  backup="$HOME/.config/nvim.backup-${stamp}"
  log "Backing up existing ~/.config/nvim -> $backup"
  cp -a "$HOME/.config/nvim" "$backup"
fi

mkdir -p "$HOME/.config/nvim/lua/configs" "$HOME/.config/nvim/lua/plugins"

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

vim.lsp.config("ts_ls", {
  cmd = { vim.fn.expand("~/.local/bin/typescript-language-server"), "--stdio" },
})

vim.lsp.enable({ "html", "cssls", "ts_ls" })
LUA

cat > "$HOME/.config/nvim/lua/plugins/init.lua" <<'LUA'
return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("gopls", {})
      vim.lsp.enable("gopls")
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
  {
    "kkrampis/codex.nvim",
    lazy = true,
    cmd = { "Codex", "CodexToggle" },
    keys = {
      { "<leader>cc", function() require("codex").toggle() end, desc = "Toggle Codex popup or side-panel", mode = { "n", "t" } },
    },
    opts = { keymaps = { toggle = nil, quit = "<C-q>" }, border = "rounded", width = 0.8, height = 0.8, autoinstall = true, panel = false, use_buffer = false },
  },
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    config = function() vim.g.mkdp_auto_start = 1 end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    config = function() require("render-markdown").setup({}) end,
  },
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      opts.completion = opts.completion or {}
      opts.completion.completeopt = "menu,menuone,noinsert,noselect"
      opts.preselect = cmp.PreselectMode.None
      opts.experimental = opts.experimental or {}
      opts.experimental.ghost_text = true
      opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_next_item()
          elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
          else fallback() end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
          else fallback() end
        end, { "i", "s" }),
        ["<CR>"] = cmp.mapping.confirm { select = false },
      })
      return opts
    end,
  },
}
LUA

cat > "$HOME/.config/nvim/lazy-lock.json" <<'JSON'
{
  "LuaSnip": { "branch": "master", "commit": "a62e1083a3cfe8b6b206e7d3d33a51091df25357" },
  "NvChad": { "branch": "v2.5", "commit": "d042cc975247c2aa55fcb228e5d146dc1dc6c648" },
  "auto-save.nvim": { "branch": "main", "commit": "979b6c82f60cfa80f4cf437d77446d0ded0addf0" },
  "base46": { "branch": "v3.0", "commit": "884b990dcdbe07520a0892da6ba3e8d202b46337" },
  "cmp-async-path": { "branch": "main", "commit": "f8af3f726e07f2e9d37672eaa9102581aefce149" },
  "cmp-buffer": { "branch": "main", "commit": "b74fab3656eea9de20a9b8116afa3cfc4ec09657" },
  "cmp-nvim-lsp": { "branch": "main", "commit": "cbc7b02bb99fae35cb42f514762b89b5126651ef" },
  "cmp-nvim-lua": { "branch": "main", "commit": "e3a22cb071eb9d6508a156306b102c45cd2d573d" },
  "cmp_luasnip": { "branch": "master", "commit": "98d9cb5c2c38532bd9bdb481067b20fea8f32e90" },
  "codex.nvim": { "branch": "main", "commit": "4317788afc091d5e913109c55d5a04f32be4e14a" },
  "conform.nvim": { "branch": "master", "commit": "dca1a190aa85f9065979ef35802fb77131911106" },
  "friendly-snippets": { "branch": "main", "commit": "6cd7280adead7f586db6fccbd15d2cac7e2188b9" },
  "gitsigns.nvim": { "branch": "main", "commit": "dd3f588bacbeb041be6facf1742e42097f62165d" },
  "indent-blankline.nvim": { "branch": "master", "commit": "d28a3f70721c79e3c5f6693057ae929f3d9c0a03" },
  "lazy.nvim": { "branch": "main", "commit": "306a05526ada86a7b30af95c5cc81ffba93fef97" },
  "markdown-preview.nvim": { "branch": "master", "commit": "a923f5fc5ba36a3b17e289dc35dc17f66d0548ee" },
  "mason.nvim": { "branch": "main", "commit": "cb8445f8ce85d957416c106b780efd51c6298f89" },
  "menu": { "branch": "main", "commit": "7a0a4a2896b715c066cfbe320bdc048091874cc6" },
  "minty": { "branch": "main", "commit": "aafc9e8e0afe6bf57580858a2849578d8d8db9e0" },
  "nvim-autopairs": { "branch": "master", "commit": "59bce2eef357189c3305e25bc6dd2d138c1683f5" },
  "nvim-cmp": { "branch": "main", "commit": "a1d504892f2bc56c2e79b65c6faded2fd21f3eca" },
  "nvim-lspconfig": { "branch": "master", "commit": "31026a13eefb20681124706a79fc1df6bf11ab27" },
  "nvim-tree.lua": { "branch": "master", "commit": "f9bfc0059eca24546b69a7006110463da4808f8f" },
  "nvim-treesitter": { "branch": "main", "commit": "4916d6592ede8c07973490d9322f187e07dfefac" },
  "nvim-web-devicons": { "branch": "master", "commit": "4fc505ac7bd7692824a142e96e5f529c133862f8" },
  "plenary.nvim": { "branch": "master", "commit": "74b06c6c75e4eeb3108ec01852001636d85a932b" },
  "render-markdown.nvim": { "branch": "main", "commit": "3f3eea97b80839f629c951ca660ffd125bfa5b34" },
  "telescope.nvim": { "branch": "master", "commit": "f04ab730b8f9c6bf3f54a206d0dcddfd70c52d59" },
  "ui": { "branch": "v3.0", "commit": "cb75908a86720172594b30de147272c1b3a7f452" },
  "volt": { "branch": "main", "commit": "620de1321f275ec9d80028c68d1b88b409c0c8b1" },
  "which-key.nvim": { "branch": "main", "commit": "3aab2147e74890957785941f0c1ad87d0a44c15a" }
}
JSON

if command -v npm >/dev/null 2>&1; then
  mkdir -p "$HOME/.local"
  npm config set prefix "$HOME/.local" >/dev/null 2>&1 || true
  if [ ! -x "$HOME/.local/bin/typescript-language-server" ]; then
    log "Installing typescript-language-server in ~/.local/bin"
    npm install -g typescript typescript-language-server >/dev/null
  fi
fi

log "Syncing Neovim plugins"
nvim --headless '+Lazy! sync' +qa

# -----------------------------
# Manual steps after setup
# -----------------------------
# 1) Reload shell config:
#    source ~/.zshrc
# 2) Open Neovim once:
#    nvim
# 3) Install LSP/formatter tools from Mason (inside nvim), if missing:
#    :MasonInstall gopls html-lsp css-lsp lua-language-server stylua
# 4) Ensure external formatters exist in PATH if you use them:
#    gofmt (Go), black (Python), clang-format (C)
# 5) If markdown preview fails, open a markdown file and run:
#    :Lazy build markdown-preview.nvim

log "Setup complete"
log "Open a new shell or run: source ~/.zshrc"
log "Then open nvim and run: :MasonInstall gopls html-lsp css-lsp lua-language-server stylua"
log "If needed, install external formatters: gofmt, black, clang-format"
