#!/bin/bash -eux

echo '==> Removing unnecessary applications to reduce box size'

apt-get -y remove --purge \
    thunderbird \
    thunderbird-locale-en \
    drawing \
    transmission-common \
    celluloid \
    transmission-common \
    hypnotix \
    rhythmbox \
    libreoffice-common \
    libreoffice-uiconfig-common \
    libreoffice-style-colibre \
    libreoffice-uiconfig-calc \
    libreoffice-uiconfig-draw \
    libreoffice-uiconfig-impress \
    libreoffice-uiconfig-writer

apt-get autoremove -y --purge
apt-get autoclean