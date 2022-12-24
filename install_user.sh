#!/usr/bin/env bash

run() {
    update-system
    download-paclist
    download-yaylist
    install-yay
    install-wifi-driver    # for my TP-Link wifi adapter
    install-apps
    create-directories
    install-dotfiles
    install-ghapps
}

update-system() {
    sudo pacman -Syu --noconfirm
}

download-paclist() {
    paclist_path="/tmp/paclist" 
    curl "https://raw.githubusercontent.com/Twilight4/arch-install-1/master/paclist" > "$paclist_path"

    echo $paclist_path
}

download-yaylist() {
    yaylist_path="/tmp/yaylist"
    curl "https://raw.githubusercontent.com/Twilight4/arch-install-1/master/yaylist" > "$yaylist_path"

    echo $yaylist_path
}

install-yay() {
    sudo pacman -S --noconfirm git
    git clone https://aur.archlinux.org/yay-bin \
    && cd yay-bin \
    && makepkg --noconfirm -si \
    && cd - \
    && rm -rf yay-bin
}

install-wifi-driver() {
    sudo pacman -S --noconfirm linux-headers dkms 
    git clone https://github.com/Mange/rtl8192eu-linux-driver \
    && cd rtl8192eu-linux-driver \
    && sudo dkms add . \
    && sudo dkms install rtl8192eu/1.0 \
    && echo "blacklist rtl8xxxu" | sudo tee /etc/modprobe.d/rtl8xxxu.conf \
    && echo -e "8192eu\n\nloop" | sudo tee /etc/modules \
    && echo "options 8192eu rtw_power_mgnt=0 rtw_enusbss=0" | sudo tee /etc/modprobe.d/8192eu.conf \
    && sudo bootctl update \
}

install-apps() {
    sudo pacman -S --noconfirm $(cat /tmp/paclist)
    yay -S --noconfirm $(cat /tmp/yaylist)
            
    # zsh as default terminal for user
    sudo chsh -s "$(which zsh)" "$(whoami)"
    
    # for razer gears
    sudo groupadd plugdev
    sudo usermod -aG plugdev "$(whoami)"
    
    # wifi TP-Link driver
    curl -LO https://raw.githubusercontent.com/Twilight4/arch-install/master/wifi-driver.sh
    bash wifi-driver.sh
    
    # for hyprland
    sudo mv ~/dotfiles/hyprland.desktop /usr/share/wayland-sessions/hyprland.desktop
      
    ## for Docker
    #gpasswd -a "$name" docker
    #usermod -aG docker $(whoami)
    #sudo systemctl enable docker.service
}

create-directories() {
#sudo mkdir -p "/home/$(whoami)/{Document,Download,Video,workspace,Music}"
mkdir -p "/home/$(whoami)/Pictures/screenshots"
}

install-dotfiles() {
    DOTFILES="/tmp/dotfiles"
    if [ ! -d "$DOTFILES" ]
        then
            git clone --recurse-submodules "https://github.com/Twilight4/dotfiles" "$DOTFILES" >/dev/null
    fi
    
    sudo mv -u /tmp/dotfiles/.config/* "$HOME/.config"
    source "/home/$(whoami)/.config/zsh/.zshenv"
    sudo rm -rf /usr/share/fonts
    sudo rm "/home/$(whoami)/.config/.local/share/fonts/README.md"
    sudo fc-cache -fv
    sudo rm /home/$(whoami)/.bash*
    sudo chmod 755 $HOME/.config/.local/bin/wrappedh1
    sudo chmod 755 $XDG_CONFIG_HOME/hypr/scripts/*
    #sudo chmod 755 $XDG_CONFIG_HOME/polybar/launch.sh              # outdated
    #sudo chmod 755 $HOME/.config/polybar/polybar-scripts/*         # outdated
    sudo chmod 755 $HOME/.config/rofi/applets/bin/*
    sudo chmod 755 $XDG_CONFIG_HOME/rofi/applets/shared/theme.bash
    sudo chmod 755 $XDG_CONFIG_HOME/rofi/launcher/launcher.sh
    sudo chmod 755 $XDG_CONFIG_HOME/zsh/bash-scripts/*.sh
    git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
    git config --global user.email "electrolight071@gmail.com"
    git config --global user.name "Twilight4"
    sudo curl https://raw.githubusercontent.com/Twilight4/arch-install/main/grub > /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

install-ghapps() {
    GHAPPS="/opt/github/essentials"
    if [ ! -d "$GHAPPS" ]
        then
        sudo mkdir -p $GHAPPS &&
        sudo git clone "https://github.com/shlomif/lynx-browser"
        sudo git clone "https://github.com/chubin/cheat.sh"
        sudo git clone "https://github.com/smallhadroncollider/taskell"
        sudo git clone "https://github.com/Swordfish90/cool-retro-term"
    fi
    

# tmux plugin manager
[ ! -d "$XDG_CONFIG_HOME/tmux/plugins/tpm" ] \
&& git clone --depth 1 https://github.com/tmux-plugins/tpm \
"$XDG_CONFIG_HOME/tmux/plugins/tpm"

echo 'Post-Installation:
- NOW DO THIS COMMAND AS ROOT: echo 'export ZDOTDIR="$HOME"/.config/zsh' > /etc/zsh/zshenv and then do: systemctl reboot -i
- sshcreate <name> - Add pub key to github: Settings > SSH > New
- reload tpm: ctrl + a + shift + i and hit q
'
}

run "$@"
