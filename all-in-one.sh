#!/usr/bin/env -S bash -e

# Cleaning the TTY
clear

# Colours for text
BOLD='\e[1m'
BRED='\e[91m'
BBLUE='\e[34m'  
BGREEN='\e[92m'
BYELLOW='\e[93m'
RESET='\e[0m'

# Pretty print
info_print () {
    echo -e "${BOLD}${BGREEN}[ ${BYELLOW}•${BGREEN} ] $1${RESET}"
}

# Pretty print for input
input_print () {
    echo -ne "${BOLD}${BYELLOW}[ ${BGREEN}•${BYELLOW} ] $1${RESET}"
}

# Alert user of bad input
error_print () {
    echo -e "${BOLD}${BRED}[ ${BBLUE}•${BRED} ] $1${RESET}"
}

# Virtualization check
virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   info_print "KVM has been detected, setting up guest tools."
                pacstrap /mnt qemu-guest-agent &>/dev/null
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
        vmware  )   info_print "VMWare Workstation/ESXi has been detected, setting up guest tools."
                    pacstrap /mnt open-vm-tools >/dev/null
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    info_print "VirtualBox has been detected, setting up guest tools."
                    pacstrap /mnt virtualbox-guest-utils &>/dev/null
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
        microsoft ) info_print "Hyper-V has been detected, setting up guest tools."
                    pacstrap /mnt hyperv &>/dev/null
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
    esac
}

# Selecting a kernel to install
kernel_selector () {
    info_print "List of kernels:"
    info_print "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
    info_print "2) Zen Kernel: A Linux kernel optimized for desktop usage"
    input_print "Please select the number of the corresponding kernel: " 
    read -r kernel_choice
    case $kernel_choice in
        1 ) kernel="linux"
            return 0;;
        2 ) kernel="linux-zen"
            return 0;;
        * ) error_print "You did not enter a valid selection, please try again."
            return 1
    esac
}

# Selecting keyboard layout
keyboard_selector () {
    input_print "Please insert the keyboard layout to use in console (enter empty to use US, or \"/\" to look up for keyboard layouts): "
    read -r kblayout
    case "$kblayout" in
        '') kblayout="us"
            info_print "The standard US keyboard layout will be used."
            return 0;;
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               error_print "The specified keymap doesn't exist."
               return 1
           fi
        info_print "Changing console layout to $kblayout."
        loadkeys "$kblayout"
        return 0
    esac
}


# Welcome screen
echo -ne "${BOLD}${BYELLOW}
  dP              oo dP oo          dP         dP   MMP"""""YMM MP""""""`MM 
  88                 88             88         88   M' .mmm. `M M  mmmmm..M 
d8888P dP  dP  dP dP 88 dP .d8888b. 88d888b. d8888P M  MMMMM  M M.      `YM 
  88   88  88  88 88 88 88 88'  `88 88'  `88   88   M  MMMMM  M MMMMMMM.  M 
  88   88.88b.88' 88 88 88 88.  .88 88    88   88   M. `MMM' .M M. .MMM'  M 
  dP   8888P Y8P  dP dP dP `8888P88 dP    dP   dP   MMb     dMM Mb.     .dM 
                                .88                 MMMMMMMMMMM MMMMMMMMMMM 
                            d8888P                                          
${RESET}"
info_print "Welcome to Twilight4's OS isntallation script, a script made in order to simplify the process of installing Arch Linux."

# Setting up keyboard layout.
until keyboard_selector; do : ; done
