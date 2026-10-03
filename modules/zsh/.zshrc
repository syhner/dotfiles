export EDITOR=vim

# enable vi mode (defaults to insert)
bindkey -v
# make escaping to normal mode instant
KEYTIMEOUT=1

# Browse history as ghost text without replacing the prefix being edited.
zmodload zsh/parameter
typeset -ga _history_suggestion_matches
typeset -g _history_suggestion_prefix
typeset -gi _history_suggestion_index=0
typeset -gi _history_suggestion_recalling=0
typeset -gaU ZSH_AUTOSUGGEST_IGNORE_WIDGETS
ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(history-suggestion-up history-suggestion-down)

_history_suggestion_browse() {
  emulate -L zsh
  local direction=$1 entry key
  local -A seen

  if [[ $LASTWIDGET != history-suggestion-up &&
        $LASTWIDGET != history-suggestion-down ]]; then
    _history_suggestion_recalling=0
  fi

  # Empty lines retain ordinary history recall; allow a standalone .zshrc too.
  if [[ -z $BUFFER ]] || (( _history_suggestion_recalling ||
                            ! ${+widgets[autosuggest-suggest]} )); then
    _history_suggestion_recalling=1
    zle autosuggest-clear 2>/dev/null
    if (( direction > 0 )); then
      zle .up-line-or-history
    else
      zle .down-line-or-history
    fi
    return
  fi

  if [[ $LASTWIDGET != history-suggestion-up &&
        $LASTWIDGET != history-suggestion-down ]] ||
     [[ $BUFFER != $_history_suggestion_prefix ]]; then
    _history_suggestion_prefix=$BUFFER
    _history_suggestion_matches=()
    _history_suggestion_index=0
    for key in ${(Onk)history}; do
      entry=$history[$key]
      if [[ $entry == "$BUFFER"* && $entry != "$BUFFER" &&
            -z ${seen[$entry]} ]]; then
        _history_suggestion_matches+=("$entry")
        seen[$entry]=1
      fi
    done
  fi

  # A pending async fetch must not overwrite the history selection.
  if [[ -n $_ZSH_AUTOSUGGEST_ASYNC_FD ]]; then
    zle -F "$_ZSH_AUTOSUGGEST_ASYNC_FD"
    exec {_ZSH_AUTOSUGGEST_ASYNC_FD}<&-
    unset _ZSH_AUTOSUGGEST_ASYNC_FD
  fi

  (( _history_suggestion_index += direction ))
  (( _history_suggestion_index < 0 )) && _history_suggestion_index=0
  (( _history_suggestion_index > $#_history_suggestion_matches )) &&
    _history_suggestion_index=$#_history_suggestion_matches
  zle autosuggest-suggest -- "${_history_suggestion_matches[$_history_suggestion_index]}"
}

_history_suggestion_up() { _history_suggestion_browse 1 }
_history_suggestion_down() { _history_suggestion_browse -1 }
zle -N history-suggestion-up _history_suggestion_up
zle -N history-suggestion-down _history_suggestion_down

# Let autosuggestions accept only as far as this single-character move goes.
_suggestion_forward_char() { zle .forward-char }
zle -N suggestion-forward-char _suggestion_forward_char
typeset -gaU ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(suggestion-forward-char)

# in vi insert/cmd mode
for keymap in viins vicmd; do
  # line navigation: cmd + left/right
  bindkey -M "$keymap" '^A' beginning-of-line
  bindkey -M "$keymap" '^E' end-of-line

  # word navigation: option + left/right
  bindkey -M "$keymap" $'\eb' backward-word
  bindkey -M "$keymap" $'\ef' forward-word

  # Accept one character with right; cmd + right above accepts the whole line.
  bindkey -M "$keymap" '^[[C' suggestion-forward-char

  # history suggestions by typed prefix: up/down (CSI and application mode)
  bindkey -M "$keymap" '^[[A' history-suggestion-up
  bindkey -M "$keymap" '^[[B' history-suggestion-down
  bindkey -M "$keymap" '^[OA' history-suggestion-up
  bindkey -M "$keymap" '^[OB' history-suggestion-down
  bindkey -M "$keymap" '^[OC' suggestion-forward-char
done

nixswitch() {
  local flakeDir="${HOME}/dotfiles"
  local ran=false

  if command -v nixos-rebuild >/dev/null 2>&1; then
    sudo nixos-rebuild switch --flake "$flakeDir" "$@"
    ran=true
  fi

  if command -v darwin-rebuild >/dev/null 2>&1; then
    sudo darwin-rebuild switch --flake "$flakeDir" "$@"
    ran=true
  fi

  # this will only run if nixos-rebuild or darwin-rebuild don't already run home manager as a system module, since the home-manager CLI is not available after those rebuilds
  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$flakeDir" "$@"
    ran=true
  fi

  if [ "$ran" = false ]; then
    echo "No supported Nix rebuild command found (nixos-rebuild, darwin-rebuild, home-manager)"
    return 1
  fi
}

bak() {
  local keep=0

  while [ $# -gt 0 ]; do
    case "$1" in
      -k|--keep)
        keep=1
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo "bak: unknown option '$1'" >&2
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 1 ]; then
    echo "usage: bak [-k|--keep] <path to file>" >&2
    return 1
  fi

  local src="$1"

  if [ ! -e "$src" ]; then
    echo "bak: '$src' does not exist" >&2
    return 1
  fi

  local n=1
  while [ -e "${src}.bak-${n}" ]; do
    n=$((n + 1))
  done

  local dst="${src}.bak-${n}"

  if [ "$keep" -eq 1 ]; then
    cp -a -- "$src" "$dst"
    echo "copied '$src' -> '$dst'"
  else
    mv -- "$src" "$dst"
    echo "moved '$src' -> '$dst'"
  fi
}

cx() {
  codex exec \
    -m gpt-5.6-luna \
    -c 'model_reasoning_effort="none"' \
    --skip-git-repo-check \
    "$*"
}
