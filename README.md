# babeuloula.zsh-theme

My own theme for zsh. It's a fork of [agnoster](https://github.com/agnoster/agnoster-zsh-theme).

A [Nerd Font](https://github.com/ryanoasis/nerd-fonts) or [Powerline-patched font](https://github.com/powerline/fonts) is required for this theme to render correctly.

## Installation — Linux (Debian/Ubuntu)

1. Install dependencies:
   ```sh
   sudo apt-get install fonts-powerline zsh
   ```
2. Start zsh and install oh-my-zsh:
   ```sh
   zsh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```
3. Download the theme:
   ```sh
   curl -o ~/.oh-my-zsh/custom/themes/babeuloula.zsh-theme \
     https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme
   ```
4. Edit `~/.zshrc`:
   - Replace `ZSH_THEME="robbyrussell"` with `ZSH_THEME="babeuloula"`
   - Add `setopt correct`
5. Reload: `source ~/.zshrc`

## Installation — macOS

1. Install [Homebrew](https://brew.sh) if not already installed.
2. Install dependencies:
   ```sh
   brew install zsh
   brew install --cask font-hack-nerd-font
   ```
   Then configure your terminal (iTerm2 → Preferences → Profiles → Text, or Terminal.app → Preferences → Profiles → Font) to use **Hack Nerd Font** or another Nerd Font.
3. Install oh-my-zsh:
   ```sh
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```
4. Download the theme:
   ```sh
   curl -o ~/.oh-my-zsh/custom/themes/babeuloula.zsh-theme \
     https://raw.githubusercontent.com/babeuloula/babeuloula-zsh-theme/master/babeuloula.zsh-theme
   ```
5. Edit `~/.zshrc`:
   - Replace `ZSH_THEME="robbyrussell"` with `ZSH_THEME="babeuloula"`
   - Add `setopt correct`
6. Reload: `source ~/.zshrc`

## Configuration

### Disable emoji icons

If your terminal does not render emoji correctly (e.g., on servers or in minimal environments), add these lines to your `~/.zshrc` **before** `source $ZSH/oh-my-zsh.sh`:

```sh
ZSH_THEME_BABEULOULA_CLOCK_ICON=""
ZSH_THEME_BABEULOULA_TIMER_ICON=""
```

### Solarized light theme

Add to `~/.zshrc` before sourcing oh-my-zsh:

```sh
SOLARIZED_THEME="light"
```
