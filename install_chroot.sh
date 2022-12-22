#!/bin/bash

# e - script stops on error
# u - error if undefined variable
# o pipefail - script fails if command piped fails
set -euo pipefail

run() {
    output=$(cat /var_output)
    log INFO "FETCH VARS FROM FILES" "$output"
    uefi=$(cat /var_uefi)
    hd=$(cat /var_disk)
    hostname=$(cat /var_hostname)
    url_installer=$(cat /var_url_installer)
    dry_run=$(cat /var_dry_run)

    log INFO "INSTALL DIALOG" "$output"
    install-dialog

    log INFO "INSTALL GRUB ON $hd WITH UEFI $uefi" "$output"
    install-grub "$hd" "$uefi"

    log INFO "SET HARDWARE CLOCK" "$output"
    set-hardware-clock

    log INFO "SET TIMEZONE" "$output"
    ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
    hwclock --systohc

    log INFO "WRITE HOSTNAME: $hostname" "$output" \
    write-hostname "$hostname"

    log INFO "CONFIGURE LOCALE" "$output"
    configure-locale "en_US.UTF-8" "UTF-8"

    log INFO "ADD ROOT" "$output"
    dialog --title "root password" --msgbox "Password for the root user" 10 60
    config_user root

    log INFO "ADD USER" "$output"
    dialog --title "Add User" --msgbox "Create new user." 10 60

    config_user
    set-leftovers

    continue-install "$url_installer"
}

log() {
    local -r level=${1:?}
    local -r message=${2:?}
    local -r output=${3:?}
    local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo -e "${timestamp} [${level}] ${message}" >>"$output"
}

write-hostname() {
    local -r hostname=${1:?}
    echo "$hostname" > /etc/hostname
}

install-dialog() {
    pacman --noconfirm --needed -S dialog
}

install-grub() {
    local -r hd=${1:?}
    local -r uefi=${2:?}

    pacman -S --noconfirm grub

    if [ "$uefi" = 1 ]; then
        pacman -S --noconfirm efibootmgr
        grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi
    else
        grub-install "$hd"
    fi

    grub-mkconfig -o /boot/grub/grub.cfg
}

set-timezone() {
    local -r tz=${1:?}
    timedatectl set-timezone "$tz"
}

set-hardware-clock() {
    hwclock --systohc
}

configure-locale() {
    local -r locale=${1:?}
    local -r encoding=${2:?}

    echo "$locale $encoding" >> /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

config_user() {
    local name=${1:-none}

    if [ "$name" == none ]; then
        dialog --no-cancel --inputbox "Enter your username" 10 60 2> name
        name=$(cat name) && rm name
    fi

    dialog --no-cancel --passwordbox "Enter your password" 10 60 2> pass1
    dialog --no-cancel --passwordbox "Enter your password again" 10 60 2> pass2

    while [ "$(cat pass1)" != "$(cat pass2)" ]
    do
        dialog --no-cancel --passwordbox "Passwords do not match.\n\nEnter password again." 10 60 2> pass1
        dialog --no-cancel --passwordbox "Retype password." 10 60 2> pass2
    done
    pass1=$(cat pass1)

    rm pass1 pass2

    # Create user if doesn't exist
    if [[ ! "$(id -u "$name" 2> /dev/null)" ]]; then
        dialog --infobox "Adding user $name..." 4 50
        useradd -m -g wheel -s /bin/bash "$name"
    fi

    # Add password to user
    echo "$name:$pass1" | chpasswd

    # Save name for later
    echo "$name" > /tmp/var_user_name
    
}

set-leftovers() {
    curl https://raw.githubusercontent.com/Twilight4/arch-install/master/sudoers > /etc/sudoers
    echo "127.0.0.1 localhost" >> /etc/hosts
    echo "::1       localhost" >> /etc/hosts
    echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
    pacman -S --noconfirm networkmanager
    # Enable the systemd service NetworkManager.
    systemctl enable NetworkManager.service
    curl https://raw.githubusercontent.com/Twilight4/arch-install/master/pacman.conf > /etc/pacman.conf
    #curl https://raw.githubusercontent.com/Twilight4/arch-install/master/environment > /etc/environment                                    # env vars for wayland
    curl https://raw.githubusercontent.com/Twilight4/arch-install/master/hyprland.desktop > /usr/share/wayland-sessions/hyprland.desktop    # must-have for hyprland
    rmmod pcspkr
    echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
}

continue-install() {
    local -r url_installer=${1:?}

    dialog --title "Continue installation" --yesno "Do you want to install all the Twilight4's softwares and the dotfiles?" 10 60 \
        && curl "$url_installer/install_user.sh" > /home/twilight/install_user.sh
}

run "$@"
