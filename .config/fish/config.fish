set fish_greeting
set -x XDG_DATA_HOME $HOME/.local/share
set -x XDG_CONFIG_HOME $HOME/.config
set -x XDG_STATE_HOME $HOME/.local/state
set -x XDG_CACHE_HOME $HOME/.cache

if test -z (pgrep ssh-agent | string collect)
  eval (ssh-agent -c)
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
  set -Ux SSH_AGENT_PID $SSH_AGENT_PID
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
end

set -x QT_QPA_PLATFORMTHEME qt5ct
set -x WINEDLLOVERRIDES winemenubuilder.exe=d

set -x XMODIFIERS @im=xim

fish_add_path $HOME/.local/bin
#fish_add_path $HOME/.spicetify
starship init fish | source

if status is-login
    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
        startx -- -keeptty
    end
end
