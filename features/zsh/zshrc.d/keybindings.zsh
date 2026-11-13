# # enable vi mode (defaults to insert)
# bindkey -v
# # make escaping to normal mode instant
# KEYTIMEOUT=1

for keymap in viins vicmd emacs; do
  # line navigation: cmd + left/right
  bindkey -M "$keymap" '^A' beginning-of-line
  bindkey -M "$keymap" '^E' end-of-line

  # word navigation: option + left/right
  bindkey -M "$keymap" $'\eb' backward-word
  bindkey -M "$keymap" $'\ef' forward-word

  # word deletion: option + backspace/delete
  bindkey -M "$keymap" $'\e\x7f' backward-kill-word
  bindkey -M "$keymap" $'\e\b' backward-kill-word
  bindkey -M "$keymap" $'\e[3;3~' kill-word
  bindkey -M "$keymap" $'\ed' kill-word

  # Accept one character with right; cmd + right above accepts the whole line.
  bindkey -M "$keymap" '^[[C' forward-char

  # history suggestions by typed prefix: up/down (CSI and application mode)
  bindkey -M "$keymap" '^[[A' history-suggestion-up
  bindkey -M "$keymap" '^[[B' history-suggestion-down
  bindkey -M "$keymap" '^[OA' history-suggestion-up
  bindkey -M "$keymap" '^[OB' history-suggestion-down
  bindkey -M "$keymap" '^[OC' forward-char
done
