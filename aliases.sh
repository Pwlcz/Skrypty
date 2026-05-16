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