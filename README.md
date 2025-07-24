# WiFi_DeAuth

A Bash-based interactive toolkit for wireless network reconnaissance, client tracking, deauthentication attacks, MAC spoofing, and WPA handshake capture. Built using the Aircrack-ng suite, this tool is designed for **ethical Wi-Fi penetration testing** in controlled environments.

> ⚠️ This tool is intended for educational use and authorized security testing **only**. Unauthorized use on networks you do not own or have explicit permission to test is **illegal**.

---

## 🚀 Features

- Enable monitor mode on a wireless interface
- Scan nearby Wi-Fi networks using `airodump-ng`
- Select a network and identify connected clients
- Perform targeted or mass deauthentication attacks using `aireplay-ng`
- Capture WPA handshakes for audit or cracking simulations
- Randomly spoof MAC addresses using `macchanger`
- Reset interface back to managed mode
- Export client MACs to file
- Menu-driven interface for ease of use

---

## 📋 Prerequisites

Ensure the following are available on your system:

- **Operating System**: Linux (preferably Kali Linux, Parrot OS, Ubuntu)
- **Wi-Fi Adapter**: Must support **monitor mode** and **packet injection**
- **Installed Tools**:
  - [`aircrack-ng`](https://www.aircrack-ng.org/)
  - `macchanger`
  - `ifconfig`, `iwconfig` (from `net-tools` and `wireless-tools`)
  - `bash` (should be default on most Linux distros)

### 🧱 Install Dependencies (Debian/Ubuntu/Kali)

```bash
sudo apt update
sudo apt install aircrack-ng macchanger net-tools wireless-tools
````

---

## 🛠️ Installation

```bash
git clone https://github.com/DevN1212/WiFi_DeAuth.git
cd WiFi_DeAuth
chmod +x deauth.sh
```

---

## 🧑‍💻 Usage

Run the script with superuser privileges:

```bash
sudo ./deauth.sh
```

### 📚 Menu Options

| Option | Description                                |
| ------ | ------------------------------------------ |
| 0      | Enable monitor mode on selected interface  |
| 1      | Scan nearby Wi-Fi networks                 |
| 2      | Select a target network                    |
| 3      | List clients connected to selected network |
| 4      | Deauthenticate a specific client           |
| 5      | Deauthenticate all clients from network    |
| 6      | Check Wi-Fi adapter status                 |
| 7      | Change the network interface name          |
| 8      | Reset interface to managed mode            |
| 9      | Spoof MAC address of Wi-Fi interface       |
| 10     | Capture WPA handshake (for audit/crack)    |
| 11     | Cleanup temporary files                    |
| 12     | Export client MACs to text file            |
| 13     | Exit the script                            |

### ✅ Typical Flow

1. Option 0 – Enable monitor mode
2. Option 1 – Scan for networks
3. Option 2 – Select target BSSID
4. Option 3 – Scan for clients
5. Option 4/5 – Perform deauthentication attack
6. Option 10 – Capture WPA handshake (optional)
7. Option 11/8 – Clean up and reset adapter

---

## 📁 Output Files

* `scan_results-01.csv` – Wi-Fi network data
* `clients_scan-01.csv` – Connected client data
* `handshake_capture-01.cap` – WPA handshake capture
* `clients_<SSID>.txt` – Exported MACs of clients

---

## ⚖️ Legal & Ethical Disclaimer

This tool is developed for **research, ethical hacking, and authorized network security testing**. Do not use it against networks or devices you do not have **explicit permission** to assess.

> ⚠️ Unauthorized use may violate local laws and could result in legal consequences.

You are solely responsible for the use of this software.

---

## 🌟 Potential Enhancements

* Real-time packet logging and signal strength display
* GUI using `zenity` or Python for improved UX
* Integration with `aircrack-ng` for automated WPA cracking
* Detection script for deauth attacks (blue team simulation)
* Logging and reporting in JSON/CSV format

---

