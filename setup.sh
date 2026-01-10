#!/bin/bash 
cd ~ && wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz && tar -xzf go1.21.5.linux-amd64.tar.gz -C ~/ && echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
git config --global user.email "zmarrouhoussam@email.com"
git config --global user.name "hzmarrou"
git config --global credential.helper store
go mod init piscine
go get github.com/01-edu/z01
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
export PATH="$HOME/.local/kitty.app/bin:$PATH"

BRAVE_DIR="$HOME/brave-browser"
mkdir -p "$BRAVE_DIR"

APPIMAGE_URL="https://github.com/srevinsaju/Brave-AppImage/releases/download/v1.88.7/Brave-nightly-v1.88.7-x86_64.AppImage"
APPIMAGE_FILE="$BRAVE_DIR/brave-nightly.AppImage"

echo "Downloading Brave AppImage..."
curl -L -o "$APPIMAGE_FILE" "$APPIMAGE_URL"

chmod +x "$APPIMAGE_FILE"

if ! grep -q 'export PATH="$HOME/brave-browser:$PATH"' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/brave-browser:$PATH"' >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
fi

CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH name "BraveBrowser"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH command "$APPIMAGE_FILE"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_PATH binding "<Control>b"

echo "✅ Brave installed in $BRAVE_DIR"
echo "✅ Ctrl+B is now bound to launch Brave"
echo "You may need to restart your session for the shortcut to take effect."

# Set shortcut for "Launch Terminal" (Ctrl + enter)
gsettings set org.gnome.desktop.default-applications.terminal exec "$HOME/.local/kitty.app/bin/kitty"; gsettings set org.gnome.desktop.default-applications.terminal exec-arg ""; gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>Return']"
# Set shortcut for "Minimize Window" (Ctrl + M)
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Ctrl>m']"
# Set shortcut for "Maximize Window" (Super + Up Arrow)
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
# Set shortcut for "Close Window" (Ctrl + q)
gsettings set org.gnome.desktop.wm.keybindings close "['<Ctrl>q']"
# Set shortcut for "Switch Windows" (Alt + Tab)
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"
# Set shortcut for "Switch between workspaces" (Ctrl + Alt + Arrow)
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Ctrl>Left']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Ctrl>Right']"

# Set shortcut for "Show/hide the dock" (Super + D)
gsettings set org.gnome.shell.keybindings toggle-dash "['<Super>d']"

# Set shortcut for "Take a screenshot" (Print Screen)
gsettings set org.gnome.settings-daemon.plugins.media-keys.screenshot "['<Print>']"

# Set shortcut for "Take a screenshot of a selected area" (Shift + shift + s Screen)
gsettings set org.gnome.settings-daemon.plugins.media-keys.area-screenshot "['<Ctrl><Shift>s']"
# Set shortcut for "Lock Screen" (Super + L)
gsettings set org.gnome.desktop.screensaver lock "['<Super>l']"
# Set shortcut for "Log Out" (Super + Shift + Q)
gsettings set org.gnome.settings-daemon.plugins.media-keys.logout "['<Super><Shift>q']"
# Set shortcut for "Open System Settings" (Super + E)
gsettings set org.gnome.settings-daemon.plugins.media-keys.preferences "['<Super>e']"
#switching between workspackes
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Ctrl>Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Ctrl>Down']"
#moving wondow to workspace 
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Shift><Ctrl><Alt>Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Shift><Ctrl><Alt>Down']"
#change all workspases 
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Ctrl>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Ctrl>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Ctrl>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Ctrl>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Ctrl>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Ctrl>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Ctrl>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Ctrl>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Ctrl>9']"
#moving windows from workspaces
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Ctrl>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Ctrl>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Ctrl>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Ctrl>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Ctrl>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Ctrl>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Ctrl>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Ctrl>8']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-9 "['<Shift><Ctrl>9']"
mkdir -p "$HOME/.config/kitty"

cat <<'EOF' > "$HOME/.config/kitty/kitty.conf"
foreground #ffe164
background #1e1e1e
background_opacity 0.5
cursor #ffffff
selection_foreground #000000
selection_background #ffff00
EOF

if command -v kitty >/dev/null 2>&1; then
    kitty @ set-colors --all "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
fi

echo "Kitty configured! Restart Kitty to see changes."

git clone https://github.com/NvChad/starter ~/.config/nvim
truncate -s 0 ~/.config/nvim/lua/plugins/init.lua
cat <<'EOF' > ~/.config/nvim/lua/plugins/init.lua
return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

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
      require("auto-save").setup {}
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

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}
EOF
echo "instalation complite \n but now you need to run source ~/.zshrc\nGo inside nvchad and run :MasonInstall gopls"
