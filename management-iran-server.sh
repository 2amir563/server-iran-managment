#!/bin/bash

# --- Color Codes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Add Alias for easy access ---
SCRIPT_PATH="$(pwd)/management-iran-server.sh"
if ! grep -q "iran-manager" ~/.bashrc; then
    echo "alias iran-manager='$SCRIPT_PATH'" >> ~/.bashrc
    echo -e "${GREEN}Alias 'iran-manager' added to .bashrc${NC}"
    source ~/.bashrc 2>/dev/null
fi

# --- Function to Install Packages via dpkg ---
install_pkg() {
    local name=$1
    local url=$2
    echo -e "${YELLOW}Installing $name...${NC}"
    wget -q -O "/tmp/$name.deb" "$url"
    if [ $? -eq 0 ]; then
        sudo dpkg -i "/tmp/$name.deb"
        rm "/tmp/$name.deb"
        echo -e "${GREEN}$name installed successfully.${NC}"
    else
        echo -e "${RED}Failed to download $name${NC}"
    fi
}

# --- Function to Configure DNS & Hosts (Improved) ---
setup_network_fix() {
    echo -e "${YELLOW}Configuring DNS and Hosts file (Permanent Fix)...${NC}"
    
    # Unlock files for editing
    sudo chattr -i /etc/resolv.conf /etc/hosts 2>/dev/null
    
    # Update Hosts for GitHub and others
    if ! grep -q "raw.githubusercontent.com" /etc/hosts; then
        echo -e "\n185.199.108.133 raw.githubusercontent.com" >> /etc/hosts
        echo -e "185.199.109.133 raw.githubusercontent.com" >> /etc/hosts
        echo -e "185.199.110.133 raw.githubusercontent.com" >> /etc/hosts
        echo -e "185.199.111.133 raw.githubusercontent.com" >> /etc/hosts
        echo -e "${GREEN}GitHub hosts added successfully.${NC}"
    fi

    # DNS Configuration Question
    echo -e "1. Use Default DNS (8.8.8.8, 1.1.1.1)"
    echo -e "2. Enter Custom DNS (Agar DNS ekhtesasi darid)"
    read -p "Select DNS option: " dns_opt
    
    if [ "$dns_opt" == "2" ]; then
        read -p "Enter Primary DNS (e.g. 10.10.10.10): " dns1
        read -p "Enter Secondary DNS (e.g. 4.2.2.4): " dns2
        echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
    else
        echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
    fi
    
    # Lock files to prevent system from changing them after reboot
    sudo chattr +i /etc/resolv.conf /etc/hosts
    echo -e "${GREEN}DNS and Hosts are now LOCKED and will not reset!${NC}"
}

# --- Function to Change SSH Port ---
change_ssh_port() {
    read -p "Enter new SSH port (Recommended: 8443 or 443): " new_port
    echo -e "${YELLOW}Changing SSH port to $new_port...${NC}"
    sudo sed -i "s/^#\?Port .*/Port $new_port/" /etc/ssh/sshd_config
    if command -v ufw &> /dev/null; then
        sudo ufw allow $new_port/tcp
    fi
    sudo systemctl restart ssh
    echo -e "${GREEN}SSH Port changed to $new_port. Please test before logout!${NC}"
}

# --- Function to Enable BBR ---
enable_bbr() {
    echo -e "${YELLOW}Enabling BBR Speed Booster...${NC}"
    if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        sudo sysctl -p
        echo -e "${GREEN}BBR Enabled Successfully!${NC}"
    else
        echo -e "${CYAN}BBR is already enabled.${NC}"
    fi
}

# --- Function for RAM & Cache Optimization ---
optimize_ram() {
    echo -e "${YELLOW}Cleaning RAM Cache...${NC}"
    sync; echo 3 | sudo tee /proc/sys/vm/drop_caches
    echo -e "${GREEN}RAM Cache cleared successfully.${NC}"
}

# --- Main Menu ---
display_menu() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${YELLOW}       SERVER MANAGEMENT & TUNNEL TOOLS          ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${RED}!!! SECURITY TIP !!!${NC}"
    echo -e "${NC}Baraye amniat dar ghot'ie internet, aval ba dastoor:${NC}"
    echo -e "${GREEN}tmux new -s management${NC}"
    echo -e "${NC}vared shavid, sepas iran-manager ra ejra konid.${NC}"
    echo -e "${CYAN}--------------------------------------------------${NC}"
    echo -e "1. Install Tools (Zip, JQ, Curl, Screen, Tmux, etc.)"
    echo -e "2. Set Timezone (Tehran) & UTF-8 (Persian Support)"
    echo -e "3. Fix DNS & Hosts (Permanent & Custom DNS Support)"
    echo -e "4. Rathole Tunnel - IRAN Server"
    echo -e "5. Rathole Tunnel - KHAREJ Server"
    echo -e "6. Watchdog Rathole (Install/Uninstall)"
    echo -e "7. Dagger Tunnel - IRAN Server"
    echo -e "8. Dagger Tunnel - KHAREJ Server"
    echo -e "9. Setup Auto-Restart Scheduler"
    echo -e "11. Clear RAM Cache (Manual)"
    echo -e "12. Setup Auto-Clear RAM (Every 231 Mins & Boot)"
    echo -e "13. Enable BBR (Speed & Network Optimizer)"
    echo -e "14. Change SSH Port (Anti-Filter Port)"
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
            install_pkg "zip" "https://bayanbox.ir/download/7507059655879743978/zip-3.0-11-amd64.deb"
            install_pkg "unzip" "https://bayanbox.ir/download/4551765058142887445/unzip-6.0-26ubuntu3.2-amd64.deb"
            install_pkg "jq" "https://bayanbox.ir/download/4704249055834606175/jq-1.6-1-amd64.deb"
            install_pkg "curl" "https://bayanbox.ir/download/2620187451991243943/curl-7.68.0-1ubuntu2-amd64.deb"
            install_pkg "net-tools" "https://bayanbox.ir/download/2926862857888342028/net-tools-2.10-1.1ubuntu1-arm64.deb"
            install_pkg "screen" "https://bayanbox.ir/download/6165034409908352421/screen-4.8.0-2ubuntu0.1-arm64.deb"
            install_pkg "tmux" "https://bayanbox.ir/download/7583716318989635982/tmux-3.0a-2ubuntu0.4-amd64.deb"
            install_pkg "iperf3" "https://bayanbox.ir/download/6989692815800249588/iperf3-3.7-3-amd64.deb"
            install_pkg "nload" "https://bayanbox.ir/download/1691938829080887785/nload-0.7.4-2build4-amd64.deb"
            install_pkg "htop" "https://bayanbox.ir/download/6700648099120155448/htop-2.2.0-2-arm64.deb"
            install_pkg "ping" "https://bayanbox.ir/download/3967816486007324840/iputils-ping-20250605-1ubuntu1-amd64.deb"
            install_pkg "vim" "https://bayanbox.ir/download/8165786091380549689/vim-8.1.2269-1ubuntu5.32-amd64.deb"
            read -p "Press Enter to return..." ;;
        2)
            sudo timedatectl set-timezone Asia/Tehran
            sudo localectl set-locale LANG=en_US.UTF-8
            read -p "Time and Locale updated. Press Enter..." ;;
        3)
            setup_network_fix
            read -p "Press Enter to return..." ;;
        4)
            wget -O rathole-iran.sh https://bayanbox.ir/download/1459681187354412327/rathole-iran.sh && sed -i 's/\r$//' rathole-iran.sh && chmod +x rathole-iran.sh && ./rathole-iran.sh ;;
        5)
            bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/amir198665/Rathole-Tunnel/main/rathole_v2.sh) ;;
        6)
            echo "1. Install / 2. Uninstall"
            read -p "Select: " watch_opt
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
            read -p "Operation Done. Press Enter..." ;;
        7)
            wget -qO setup.sh https://bayanbox.ir/download/6376663628506155341/setup.sh && sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh ;;
        8)
            wget -q -O setup.sh https://raw.githubusercontent.com/2amir563/-khodamneveshtamDaggerConnect/main/setup.sh && sed -i 's/\r$//' setup.sh && chmod +x setup.sh && ./setup.sh ;;
        9)
            wget -O restart-server.sh https://bayanbox.ir/download/6116420477492192131/kole-code-dastor-restart-server.sh && sed -i 's/\r$//' restart-server.sh && chmod +x restart-server.sh && ./restart-server.sh ;;
        11)
            optimize_ram
            read -p "Press Enter..." ;;
        12)
            echo "Setting up Auto-Clear RAM (Every 231 Mins & Boot)..."
            (crontab -l 2>/dev/null | grep -v "drop_caches"; echo "*/231 * * * * sync; echo 3 > /proc/sys/vm/drop_caches") | crontab -
            (crontab -l 2>/dev/null | grep -v "@reboot"; echo "@reboot sync; echo 3 > /proc/sys/vm/drop_caches") | crontab -
            echo -e "${GREEN}Auto-Optimization (231 min) enabled!${NC}"
            read -p "Press Enter..." ;;
        13)
            enable_bbr
            read -p "Press Enter..." ;;
        14)
            change_ssh_port
            read -p "Press Enter..." ;;
        10)
            clear
            echo -e "${YELLOW}--- SSH Guide for Net Melli ---${NC}"
            echo -e "1. If SSH is blocked, use Web Console (VNC) from Hosting Panel."
            echo -e "2. Change Port to 8443 or 443 to bypass filtering."
            echo -e "3. SSH via Tunnel: ssh root@localhost -p [LOCAL_PORT]"
            echo -e ""
            echo -e "${YELLOW}--- Screen & Tmux ---${NC}"
            echo -e "Screen: screen -S name -> Ctrl+A then D (Hide) -> screen -r name"
            echo -e "Tmux: tmux new -s name -> Ctrl+B then D (Hide) -> tmux attach -t name"
            echo -e ""
            echo -e "${YELLOW}--- Linux Common Commands ---${NC}"
            echo -e "rm -r [dir] / pkill -f [name] / htop / nload / df -h"
            echo -e "chattr -i /etc/resolv.conf (Unlock DNS baraye edit)"
            echo -e "chattr +i /etc/resolv.conf (Ghofl kardan DNS)"
            echo -e "--------------------------------------------"
            read -p "Press Enter to return..." ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid!${NC}" && sleep 1 ;;
    esac
done
