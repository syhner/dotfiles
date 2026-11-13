mkcd() { mkdir -p -- "$1" && cd -- "$1" }
# copy the working directory through OSC 52, so it works over SSH and in tmux
cwd() { printf '\e]52;c;%s\a' "$(print -rn -- $PWD | base64 | tr -d '\n')" }
