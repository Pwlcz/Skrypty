# source it in ~/.profile, ~/.bashrc, ~/.zshrc, etc.
alias avup="vagrant up && vagrant ssh-config >> ~/.ssh/config_vscode"

function gitignore-latex() {
  echo '# LaTeX files
*.bat
*.gz
*.aux
*.log
*.bbl
*.blg
*.lot
*.tcp
*.toc
*.lof
# End of LaTeX files' >> .gitignore
}

function pyvenv() {
  if [[ ! -d ./.venv ]]; then
    printf '%s' 'dir .venv not found. Do you want to create it now? [Y/n] '
    read -r c
    if [[ $c == [yY] ]] || [[ -z $c ]]; then 
      python -m venv .venv
    fi
  fi
  source ./.venv/bin/activate
}
