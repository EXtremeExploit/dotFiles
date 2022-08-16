function update-keepass --wraps='cd ~/dev/-stuff && cp ~/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push' --description 'Update KeePass file to github'
  cd ~/dev/-stuff && cp ~/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push $argv; 
end
