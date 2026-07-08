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
GO_VERSION="1.23.3"
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

# Optional piscine workspace
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
  gsettings set org.gnome.desktop.wm.keybindings minimize "['<Ctrl>m']" || true
  gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']" || true
  gsettings set org.gnome.desktop.wm.keybindings close "['<Ctrl>q']" || true
  gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']" || true
fi

# -----------------------------
# Neovim
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
# NvChad Setup (Fixed)
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

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)
LUA

# lazy config
cat > "$HOME/.config/nvim/lua/configs/lazy.lua" <<'LAZY'
return {
  defaults = { lazy = true },
  install = { colorscheme = { "nvchad" } },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
}
LAZY

# options.lua (with clipboard fix)
cat > "$HOME/.config/nvim/lua/options.lua" <<'LUA'
require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!
LUA

# mappings.lua (Fixed with your requested keys)
cat > "$HOME/.config/nvim/lua/mappings.lua" <<'LUA'
require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
LUA

# Other config files (unchanged)
cat > "$HOME/.config/nvim/lua/autocmds.lua" <<'LUA'
require "nvchad.autocmds"
LUA

cat > "$HOME/.config/nvim/lua/chadrc.lua" <<'LUA'
-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
        theme = "gatekeeper",

        -- hl_override = {
        --      Comment = { italic = true },
        --      ["@comment"] = { italic = true },
        -- },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
LUA

# ... (rest of your plugins remain the same)
cat > "$HOME/.config/nvim/lua/plugins/init.lua" <<'LUA'
return {

   {
  "neovim/nvim-lspconfig",
  config = function()
    -- 1. Define gopls configuration
    vim.lsp.config("gopls", {})

    -- 2. Enable the gopls server
    vim.lsp.enable("gopls")

    -- 3. Keymaps for LSP actions
    local opts = { noremap = true, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
   end,
  },
  -- Plugin for auto save

  {
  "pocco81/auto-save.nvim",
  lazy = false,
  config = function()
    require("auto-save").setup({
      enabled = false, -- disable automatic triggers
    })

    -- Save only when pressing Esc
    vim.keymap.set({ "i", "n", "v" }, "<Esc>", function()
      -- if in insert, leave insert first
      if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
      end
      -- save (silently) if the buffer can be written
      pcall(vim.cmd, "silent! update")
    end, { noremap = true, silent = true })
  end,
  },

  -- Plugin for fix format (you have to install the formatter programs
  -- of your laungage)
  {
  "stevearc/conform.nvim",
  lazy = false,
  config = function()
    require("conform").setup {
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        go = { "gofmt" },
        lua = { "stylua" },
        python = { "black" },
        c = { "clang_format" },
      },
    }

    -- manual format key (VERY important)
    vim.keymap.set("n", "<leader>f", function()
      require("conform").format()
    end, { desc = "Format file" })
  end,
  },

  {
  'kkrampis/codex.nvim',
  lazy = true,
  cmd = { 'Codex', 'CodexToggle' },
  keys = {
    {
      '<leader>cc',
      function() require('codex').toggle() end,
      desc = 'Toggle Codex popup or side-panel',
      mode = { 'n', 't' }
    },
  },
  opts = {
    keymaps = {
      toggle = nil,
      quit = '<C-q>',
    },
    border = 'rounded',
    width = 0.8,
    height = 0.8,
    model = nil,
    autoinstall = true,
    panel = false,
    use_buffer = false,
   },
  },


  --markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npm install",
    ft = { "markdown" },
    config = function()
      vim.g.mkdp_auto_start = 1
    end,
  },



  -- Meandering programer: render markdown
  {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  config = function()
    require("render-markdown").setup({})
   end,
  },



  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  --    "nvim-treesitter/nvim-treesitter",
  --    opts = {
  --            ensure_installed = {
  --                    "vim", "lua", "vimdoc",
  --      "html", "css"
  --            },
  --    },
  -- },

-- Manual completion with inline preview (ghost text)
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
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_locally_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<CR>"] = cmp.mapping.confirm { select = false },
    })

    return opts
  end,
 },
}
LUA

# Optional: npm tools
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
log " source ~/.zshrc"
log " nvim"
log "Inside Neovim, run: :MasonInstall gopls html-lsp css-lsp lua-language-server stylua"
