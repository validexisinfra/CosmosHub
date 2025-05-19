# CosmosHub
The Cosmos Hub is the first of many interconnected blockchains powered by the interchain stack: CometBFT, CosmosSDK and IBC. The primary token of the Cosmos Hub is the ATOM.

# 🌟 CosmosHub Setup & Upgrade Scripts

A collection of automated scripts for setting up and upgrading Lava nodes on **Mainnet (`cosmoshub-4`)**.

---

### ⚙️ Validator Node Setup  
Install a CosmosHub validator node with custom ports, snapshot download, and systemd service configuration.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/CosmosHub/main/installmain.sh)
~~~
---

### 🔄 Validator Node Upgrade 
Upgrade your CosmosHub node binary and safely restart the systemd service.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/CosmosHub/main/upgrademain.sh)
~~~

---

### 🧰 Useful Commands

| Task            | Command                                 |
|-----------------|------------------------------------------|
| View logs       | `journalctl -u gaiad -f -o cat`        |
| Check status    | `systemctl status gaiad`              |
| Restart service | `systemctl restart gaiad`             |
