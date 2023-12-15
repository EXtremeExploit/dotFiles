function update-keepass --wraps='cd ~ && cp ~/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push' --description 'Update KeePass file to github'
    cd ~ && cp ~/keepass.kdbx . && git add keepass.kdbx && git commit -m "Update Keepass" && git push $argv;
end
