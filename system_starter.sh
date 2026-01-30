#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    curl \
    wget \
    git \
    zsh \
    flatpak \
    unzip 

## fonts
mkdir -p /usr/share/fonts/truetype/nerd-fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/OpenDyslexic.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/NerdFontsSymbolsOnly.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/MartianMono.zip

sudo unzip OpenDyslexic.zip -d /usr/share/fonts/truetype/nerd-fonts/
sudo unzip NerdFontsSymbolsOnly.zip -d /usr/share/fonts/truetype/nerd-fonts/
sudo unzip MartianMono.zip -d /usr/share/fonts/truetype/nerd-fonts/
sudo rm /usr/share/fonts/truetype/nerd-fonts/README.md /usr/share/fonts/truetype/nerd-fonts/LICENSE*
fc-cache -fv
rm OpenDyslexic.zip NerdFontsSymbolsOnly.zip MartianMono.zip

## zsh
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
p10k configure
echo "autoload -Uz compinit; compinit" >> ~/.zshrc
# addons

## flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo