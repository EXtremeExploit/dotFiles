if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Start X at login
#if status is-login
#    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
#        exec startx -- -keeptty
#    end
#end

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

set -x ANDROID_HOME $HOME/.android
set -x XINITRC $XDG_CONFIG_HOME/X11/xinitrc

set -x XMODIFIERS @im=xim

fish_add_path /home/pedro/.local/bin
fish_add_path /home/pedro/.spicetify
starship init fish | source

# pnpm
set -gx PNPM_HOME "/home/pedro/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
set -gx PATH "$HOME/.local/bin" $PATH
#set -gx PATH "$HOME/.deno/bin" $PATH

# pnpm end
