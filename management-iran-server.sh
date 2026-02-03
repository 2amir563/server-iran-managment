#!/bin/bash

# --- Color Codes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Add Alias for easy access ---
# Islah: Masire sabet dar /root baraye kar kardan dar hame ja
SCRIPT_PATH="/root/management-iran-server.sh"
if ! grep -q "iran-manager" ~/.bashrc; then
    echo "alias iran-manager='bash $SCRIPT_PATH'" >> ~/.bashrc
    source ~/.bashrc 2>/dev/null
fi

# --- Function to Install Packages Safely (FIXED) ---
# In bakhsh islah shod: Dige az link-haye .deb khariji estefade nemishavad
install_pkg() {
    local name=$1
    echo -e "${YELLOW}Installing $name (Official Repo)...${NC}"
    
    # Map kardan name paki-ha baraye nasbe sahih
    local pkg_name=$name
    if [ "$name" == "ping" ]; then pkg_name="iputils-ping"; fi
    
    sudo apt-get install "$pkg_name" -y
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$name ok shod.${NC}"
    else
        echo -e "${RED}Khatayi dar nasbe $name pish amad.${NC}"
    fi
}

# --- Function to Configure DNS & Hosts (FINAL AUTO-FIX) ---
setup_network_fix() {
    echo -e "${YELLOW}Configuring DNS and Hosts file (Permanent Fix)...${NC}"
    
    # 1. Resolve Hostname Error (Fixes 'unable to resolve host')
    local current_hostname=$(hostname)
    sudo chattr -i /etc/hosts 2>/dev/null
    if ! grep -q "$current_hostname" /etc/hosts; then
        echo "127.0.0.1 $current_hostname" >> /etc/hosts
        echo -e "${GREEN}Hostname ($current_hostname) added to hosts file.${NC}"
    fi

    # 2. Add GitHub IPs to bypass disruptions
    sed -i '/raw.githubusercontent.com/d' /etc/hosts
    echo -e "\n185.199.108.133 raw.githubusercontent.com" >> /etc/hosts
    echo -e "185.199.109.133 raw.githubusercontent.com" >> /etc/hosts
    echo -e "185.199.110.133 raw.githubusercontent.com" >> /etc/hosts
    echo -e "185.199.111.133 raw.githubusercontent.com" >> /etc/hosts
    sudo chattr +i /etc/hosts 2>/dev/null

    # 3. DNS Configuration
    echo -e "1. Use Default DNS (8.8.8.8, 1.1.1.1)"
    echo -e "2. Enter Custom DNS"
    read -p "Select DNS option: " dns_opt
    
    sudo chattr -i /etc/resolv.conf 2>/dev/null
    if [ "$dns_opt" == "2" ]; then
        read -p "Enter Primary DNS: " dns1
        read -p "Enter Secondary DNS: " dns2
        echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
    else
        echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
    fi
    
    sudo chattr +i /etc/resolv.conf 2>/dev/null
    echo -e "${GREEN}DNS and Hosts are now FIXED and LOCKED!${NC}"
}

# --- Function to Change SSH Port ---
change_ssh_port() {
    read -p "Enter new SSH port (e.g. 8443): " new_port
    echo -e "${YELLOW}Changing SSH port to $new_port...${NC}"
    sudo sed -i "s/^#\?Port .*/Port $new_port/" /etc/ssh/sshd_config
    if command -v ufw &> /dev/null; then
        sudo ufw allow $new_port/tcp
    fi
    sudo systemctl restart ssh
    echo -e "${GREEN}SSH Port changed to $new_port.${NC}"
}

# --- Function to Enable BBR ---
enable_bbr() {
    echo -e "${YELLOW}Enabling BBR Speed Booster...${NC}"
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sudo sysctl -p
        echo -e "${GREEN}BBR Successfully Enabled!${NC}"
    else
        echo -e "${CYAN}BBR az ghabl fa'al bood.${NC}"
    fi
}

# --- Function for RAM & Cache Optimization ---
optimize_ram() {
    echo -e "${YELLOW}Cleaning RAM Cache...${NC}"
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
    echo -e "${GREEN}RAM Cache pak shod.${NC}"
}

# --- Main Menu ---
display_menu() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW}       SERVER MANAGEMENT & TUNNEL TOOLS          ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${RED}!!! SECURITY TIP !!!${NC}"
    echo -e "${NC}Aval ba dastoor: ${GREEN}tmux new -s management${NC} vared shavid.${NC}"
    echo -e "${CYAN}--------------------------------------------------${NC}"
    echo -e "1. Install All Tools (Zip, JQ, Curl, Tmux, Ping, etc. - SAFE)"
    echo -e "2. Set Timezone (Tehran) & UTF-8 Support"
    echo -e "3. Fix DNS & Hosts (Permanent & Auto Hostname Fix)"
    echo -e "4. Rathole Tunnel - IRAN Server"
    echo -e "5. Rathole Tunnel - KHAREJ Server"
    echo -e "6. Watchdog Rathole (Install/Uninstall)"
    echo -e "7. Dagger Tunnel - IRAN Server"
    echo -e "8. Dagger Tunnel - KHAREJ Server"
    echo -e "9. Setup Auto-Restart Scheduler"
    echo -e "11. Clear RAM Cache (Manual)"
    echo -e "12. Setup Auto-Clear RAM (Every 231 Mins & Boot)"
    echo -e "13. Enable BBR (Speed & Network Optimizer)"
    echo -e "14. Change SSH Port"
    echo -e "10. Help: SSH Guide, Linux Commands, Screen/Tmux"
    echo -e "0. Exit"
    echo -e "${CYAN}--------------------------------------------------${NC}"
    echo -e "${YELLOW}Shortcut command: ${GREEN}iran-manager${NC}"
}

while true; do
    display_menu
    read -p "Choose an option: " opt
    case $opt in
        1)
            sudo apt-get update
            # Islah: Inja dige be soorate automatic az مخازن رسمی nasb mishavad
            for tool in zip unzip jq curl net-tools screen tmux iperf3 nload htop ping vim; do
                install_pkg "$tool"
            done
            read -p "Baraye bazgasht Enter bezanid..." ;;
        2)
            sudo timedatectl set-timezone Asia/Tehran
            sudo localectl set-locale LANG=en_US.UTF-8
            read -p "Timezone va Locale tanzim shod. Enter bezanid..." ;;
        3)
            setup_network_fix
            read -p "Baraye bazgasht Enter bezanid..." ;;
        4)
            wget -O rathole-iran.sh https://bayanbox.ir/download/1459681187354412327/rathole-iran.sh && sed -i 's/\r$//' rathole-iran.sh && chmod +x rathole-iran.sh && ./rathole-iran.sh ;;
        5)
            bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/amir198665/Rathole-Tunnel/main/rathole_v2.sh) ;;
        6)
            echo "1. Install / 2. Uninstall"
            read -p "Entekhab konid: " watch_opt
            if [ "$watch_opt" == "1" ]; then
                wget -O /root/rathole_watchdog.sh https://bayanbox.ir/download/974175030198953681/rathole-watchdog.sh
                chmod +x /root/rathole_watchdog.sh && /root/rathole_watchdog.sh
            else
                sudo systemctl stop rathole_watchdog.service || true
                sudo systemctl disable rathole_watchdog.service || true
                sudo rm /etc/systemd/system/rathole_watchdog.service || true
                sudo systemctl daemon-reload
                pkill -f rathole_watchdog.sh || true
                rm /root/rathole_watchdog.sh /root/rathole_watchdog.conf || true
            fi
            read -p "Anjam shod. Enter bezanid..." ;;
        7)
            wget -qO setup.sh https://bayanbox.ir/download/6376663628506155341/setup.sh && sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh ;;
        8)
            wget -q -O setup.sh https://raw.githubusercontent.com/2amir563/-khodamneveshtamDaggerConnect/main/setup.sh && sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh ;;
        9)
            wget -O restart-server.sh https://bayanbox.ir/download/6116420477492192131/kole-code-dastor-restart-server.sh && sed -i 's/\r$//' restart-server.sh && chmod +x restart-server.sh && ./restart-server.sh ;;
        11)
            optimize_ram
            read -p "Enter bezanid..." ;;
        12)
            (crontab -l 2>/dev/null | grep -v "drop_caches"; echo "*/231 * * * * sync; echo 3 > /proc/sys/vm/drop_caches") | crontab -
            (crontab -l 2>/dev/null | grep -v "@reboot"; echo "@reboot sync; echo 3 > /proc/sys/vm/drop_caches") | crontab -
            echo -e "${GREEN}Auto-Optimization (231 min) fa'al shod!${NC}"
            read -p "Enter bezanid..." ;;
        13)
            enable_bbr
            read -p "Enter bezanid..." ;;
        14)
            change_ssh_port
            read -p "Enter bezanid..." ;;
        10)
            clear
            echo -e "${YELLOW}--- SSH Guide ---${NC}"
            echo -e "1. Agar SSH baste shod, az Console VNC estefade konid."
            echo -e "2. Port SSH ra be 8443 ya 443 taghyir dehid."
            echo -e ""
            echo -e "${YELLOW}--- Screen & Tmux ---${NC}"
            echo -e "Screen: screen -S name -> Ctrl+A then D -> screen -r name"
            echo -e "Tmux: tmux new -s name -> Ctrl+B then D -> tmux attach -t name"
            read -p "Enter bezanid..." ;;
        0) exit 0 ;;
        *) echo -e "${RED}Ghalat!${NC}" && sleep 1 ;;
    esac
done
