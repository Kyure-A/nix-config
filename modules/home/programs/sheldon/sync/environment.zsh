HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000

export EDITOR=emacs
export SUDO_EDITOR=emacs
export GIT_MERGE_AUTOEDIT=no

WORDCHARS=${WORDCHARS//\/[&.;]} # 単語区切り文字の設定

export STARSHIP_CONFIG=~/.config/starship.toml

[ -n "$EAT_SHELL_INTEGRATION_DIR" ] && \
  source "$EAT_SHELL_INTEGRATION_DIR/zsh"
