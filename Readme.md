
<p align="center">
<img width="300" height="500" alt="hysteria" src="https://github.com/user-attachments/assets/abf26e04-7a28-48f5-b39e-de2df7be0dc1" />
</p>

# 🚀 Hysteria + WireGuard Secure Tunnel Setup

This project provides a fully automated setup for creating a **secure and obfuscated traffic tunnel** using [Hysteria](https://github.com/apernet/hysteria) and [WireGuard](https://www.wireguard.com/).  
It enables **private, censorship-resistant transport** of network traffic through a combination of QUIC over TCP, TLS encryption, and custom routing.

---

## 📁 Contents

- `setup-hysteria-server.sh` – Installs and configures the Hysteria **server**.
- `setup-hysteria-client.sh` – Installs and configures the Hysteria **client** with WireGuard.
- `add-wg-peer.sh` – Adds a new **WireGuard peer** to your `wg1` interface safely.

---

## ✅ Features

- 🔐 Secure tunneling with **QUIC + TLS + Password Auth**
- 🧅 Built-in **obfuscation** using `salamander`
- 🌐 Fully automated **WireGuard over Hysteria**
- 🛠️ Intelligent routing using **iptables**, `ip rule`, and custom `routing table`
- 📦 Compatible with **Debian/Ubuntu**

---

## 📦 Installation

### 🖥️ Server Setup

1. SSH into your **server** (preferably located outside the filtered network).
2. Run the setup script:

```bash
    wget https://raw.githubusercontent.com/mrhn3242/WgOverHysteria/main/setup-hysteria-server.sh
    chmod +x setup-hysteria-server.sh
    ./setup-hysteria-server.sh
```

3. You'll be prompted to enter:

- 🔒 **Port** to listen on (e.g. `443`)
- 🛡️ **Auth password** (used by clients to connect)
- 🧅 **Obfuscation password** (used for `salamander` obfuscation)

The script will:

- Download and install the latest Hysteria binary
- Generate TLS certificates (self-signed)
- Create `/etc/hysteria/config.yaml`
- Start the server in the background with `nohup`

---

### 💻 Client Setup

1. SSH into your **client VPS or device**
2. Run the setup script:

```bash
    wget https://raw.githubusercontent.com/mrhn3242/WgOverHysteria/main/setup-hysteria-client.sh
    chmod +x setup-hysteria-client.sh
    ./setup-hysteria-client.sh
```

3. You'll be asked to provide:

- 🌐 **Server address** in the format `IP:PORT`
- 🔐 **Auth password** (must match the server)
- 🧅 **Obfuscation password** (must match the server)
- 🚪 **WireGuard port** for local interface

The script will:

- Install Hysteria and WireGuard
- Generate the Hysteria config at `/etc/hysteria/config.yaml`
- Create the WireGuard config at `/etc/wireguard/wg1.conf`
- Configure iptables rules and advanced routing

✅ **After reboot**, bring up the Wireguard with:

`sudo wg-quick up wg1`

---

### ➕ Add a New Peer (Optional)

To add a new WireGuard peer, use:

```bash
    wget https://raw.githubusercontent.com/mrhn3242/WgOverHysteria/main/add-peer.sh
    chmod +x add-peer.sh
    ./add-peer.sh
```

Or provide arguments directly:

`add-wg-peer.sh publickey=XXXX allowed-ips=190.22.0.9/32 persistent-keepalive=25`

The script:

- Adds the peer to the running `wg1` interface
- Appends it to `/etc/wireguard/wg1.conf` (if not already present)
