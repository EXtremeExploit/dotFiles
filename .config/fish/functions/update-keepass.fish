function update-keepass --wraps='cd ~/Documentos/dev/-stuff && cp ~/Documentos/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push' --description 'alias update-keepass=cd ~/Documentos/dev/-stuff && cp ~/Documentos/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push'
  cd ~/Documentos/dev/-stuff && cp ~/Documentos/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push $argv; 
end
