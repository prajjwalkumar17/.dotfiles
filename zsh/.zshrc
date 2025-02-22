export PATH=$PATH:/home/hangsai/.cache/pokemon-icat
pokemon-icat -q

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source $(find /nix/store -name "powerlevel10k.zsh-theme" | head -n 1)
nvim() {
    kitten @ set-spacing padding=0   # Set padding to 0
    command nvim "$@"                # Run Neovim with any passed arguments
    kitten @ set-spacing padding=25  # Restore padding to 25 after exiting Neovim
}
# FZF configuration for better history search
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_CTRL_R_OPTS="--sort --exact"

# Ensure history is saved properly
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt NO_CLOBBER

eval "$(zoxide init zsh)"

# zprof

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
