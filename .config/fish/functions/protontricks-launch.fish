function protontricks-launch --wraps='flatpak run com.github.Matoking.protontricks' --description 'Runs protontricks launch EXE'
  flatpak run --command=protontricks-launch com.github.Matoking.protontricks $argv
end
