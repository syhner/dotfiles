# Browse history as ghost text without replacing the prefix being edited.
zmodload zsh/parameter
typeset -ga _history_suggestion_matches
typeset -gi _history_suggestion_index=0
typeset -gi _history_suggestion_recalling=0
typeset -gaU ZSH_AUTOSUGGEST_IGNORE_WIDGETS
ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(history-suggestion-up history-suggestion-down)

_history_suggestion_browse() {
  emulate -L zsh
  local direction=$1 pattern="${(b)BUFFER}?*"

  if [[ $LASTWIDGET != history-suggestion-(up|down) ]]; then
    _history_suggestion_recalling=0
    _history_suggestion_index=0
    # History is newest first; (u) removes duplicates and (b) quotes the prefix.
    _history_suggestion_matches=("${(@u)history[(R)$~pattern]}")
  fi

  # Empty lines retain ordinary history recall; work without zsh-autosuggestions too.
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

# Right accepts a character; end-of-line and forward-word keep their defaults.
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=("${(@)ZSH_AUTOSUGGEST_ACCEPT_WIDGETS:#forward-char}")
typeset -gaU ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=(forward-char)
