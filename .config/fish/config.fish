if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Start X at login
#if status is-login
#    if test -z "$DISPLAY" -a "$XDG_VTNR" = 1
#        exec startx -- -keeptty
#    end
#end

set -x PICO_SDK_PATH ~/Documentos/pico-sdk
set -x QT_QPA_PLATFORMTHEME qt5ct

starship init fish | source
