#!/bin/bash
# creates udev / systemd job for automatic backups
if [[ ! -d "./configs/backup" ]]; then
    echo "Backup configuration directory not found. Does './configs/backup' exist?"
    exit 1
fi

#
# Encrypted backup password management
#

echo 'TPM_CRED_FILE="$HOME/.config/borg_pass.cred"' >> ~/.bashrc
source ~/.bashrc

if [ -c /dev/tpmrm0 ] || [ -c /dev/tpm0 ]; then
    echo "TPM module detected. Using systemd-creds..."
    if ! command -v tpm2_encryptdecrypt &> /dev/null; then
        echo "tpm2-tools not found. Installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y tpm2-tools
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu tpm2-tools
        else
            echo "Unsupported package manager. Please install tpm2-tools manually."
            exit 1
        fi
    fi

    echo 'export BORG_PASSCOMMAND="systemd-creds decrypt $TPM_CRED_FILE -"' >> ~/.bashrc
    if [ -f "$TPM_CRED_FILE" ]; then
        source ~/.bashrc
    else
        echo "Error: TPM detected, $TPM_CRED_FILE is missing."
        read -p "Enter backup password to encrypt with TPM: " -s PASSWORD
        echo -n "$PASSWORD" | systemd-creds encrypt --with-key=tpm2 - "$TPM_CRED_FILE"
        echo "Password encrypted and stored in $TPM_CRED_FILE."
        echo "Ensure the following line is in your ~/.bashrc to use TPM for Borg password management:"
        echo 'export BORG_PASSCOMMAND="systemd-creds decrypt $TPM_CRED_FILE -"'
    fi

else
    echo "No TPM module detected. Falling back to secret-tool (Keyring)..."
    
    if command -v secret-tool >/dev/null 2>&1; then
        echo 'export BORG_PASSCOMMAND="secret-tool lookup borg backup"' >> ~/.bashrc
        source ~/.bashrc
    else
        echo "Error: Install libsecret-tools."
        exit 1
    fi
fi

#
# Install systemd services and udev rules
#

cd $(dirname "$0")

if [[ -s "./configs/backup/borg-weekly.service" && \
      -s "./configs/backup/borg-weekly.timer"   && \
      -s "./configs/backup/99-usb-backup.rules" && \
      -s "./configs/backup/usb-backup@.service" && \
      -s "./configs/backup/usb-backup-timer.sh" && \
      -s "./check-backup.desktop"               && \
      -s "./check-backup-overdue.sh"            ]]; then
    # Copy systemd service and timer files to user directory
    cp ./configs/backup/borg-weekly.service "${HOME}/.config/systemd/user/" \
    && cp ./configs/backup/borg-weekly.timer "${HOME}/.config/systemd/user/" \
    && echo "Systemd service and timer files copied successfully." \
    || { echo "Failed to copy systemd service or timer files. Check permissions."; exit 1; }
    # Copy udev rule file to system directory
    sudo cp ./configs/backup/99-usb-backup.rules /etc/udev/rules.d/ \
    && echo "Udev rule copied successfully." \
    || { echo "Failed to copy udev rule. Check permissions."; exit 1; }
    # Copy udev-triggered systemd service file to system directory
    sudo cp ./configs/backup/usb-backup@.service /etc/systemd/system/ \
    && echo "Udev-triggered systemd service file copied successfully." \
    || { echo "Failed to copy udev-triggered systemd service file. Check permissions."; exit 1; }
    # Copy udev-triggered backup script to user directory
    cp ./configs/backup/usb-backup-timer.sh "${HOME}/.config/systemd/user/" \
    && echo "Udev-triggered backup script copied successfully." \
    || { echo "Failed to copy udev-triggered backup script. Check permissions."; exit 1; }
    # Copy backup notification files to user directory
    cp ./check-backup.desktop "${HOME}/.config/autostart/" \
    && cp ./check-backup-overdue.sh "${HOME}/.local/bin/" \
    && chmod +x "${HOME}/.local/bin/check-backup-overdue.sh" \
    && echo "Backup notification files copied successfully." \
    || { echo "Failed to copy backup notification files. Check permissions."; exit 1; }
else
    echo "One or more required files not found or empty."
    exit 1
fi

systemctl --user daemon-reload
systemctl --user enable borg-weekly.service borg-weekly.timer

sudo systemctl daemon-reload
sudo systemctl enable usb-backup@.service
sudo udevadm control --reload-rules

# print status of services
# systemctl status backup.service
# udevadm test /sys/class/block/sdb1

echo "Remember to backup your password outside of the TPM or Keyring, as losing access to it will result in losing access to your backups."
echo "Done."