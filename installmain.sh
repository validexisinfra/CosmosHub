#!/bin/bash

set -e

GREEN="\e[32m"
RED="\e[31m"
NC="\e[0m"

print() {
  echo -e "${GREEN}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
}

read -p "Enter your node MONIKER: " MONIKER
read -p "Enter your custom port prefix (e.g. 16): " CUSTOM_PORT

print "Installing CosmosHub Node with moniker: $MONIKER"
print "Using custom port prefix: $CUSTOM_PORT"

print "Updating system and installing dependencies..."
sudo apt update
sudo apt install -y curl git build-essential lz4 wget

sudo rm -rf /usr/local/go
curl -Ls https://go.dev/dl/go1.23.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)
echo "export PATH=$PATH:/usr/local/go/bin:/usr/local/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile

cd $HOME
rm -rf gaia
git clone https://github.com/cosmos/gaia.git
cd gaia
git checkout v24.0.0
make install

gaiad config set client chain-id cosmoshub-4
gaiad config set client keyring-backend test
gaiad config set client node tcp://localhost:${CUSTOM_PORT}657
gaiad init $MONIKER --chain-id cosmoshub-4

curl -Ls https://snapshots.kjnodes.com/cosmoshub/genesis.json > $HOME/.gaia/config/genesis.json
curl -Ls https://snapshots.kjnodes.com/cosmoshub/addrbook.json > $HOME/.gaia/config/addrbook.json

SEEDS="00bf1f9d3c65137dc99c40cd03864384ce0ef7c3@cosmoshub-mainnet-seed.itrocket.net:34656"
PEERS="2441723e318545be469d43611d331e3271477ede@cosmoshub-mainnet-peer.itrocket.net:34656,e93fbb087acb7c0f8ca850a796310bb745b510b6@23.227.220.132:26656,b6fedf0d6c87628e72cd5a82058b551445168f9f@23.88.75.75:14956,48c5af84afc9e25f62a7189f0260fd907aac5f68@204.16.247.246:26656,8220e8029929413afff48dccc6a263e9ac0c3e5e@204.16.247.237:26656,bb355f5f5c323150d22608a80fc94d67c2f638bd@169.155.47.134:26656,c98397d6dd1b180ed94a3b17903209172c81ed23@54.39.131.64:26661,63f1915e9d052a04cb11243bb90ff67879dd972c@141.98.219.28:26656,88bd49450f1e9ffef6e272b2002862b2c012c315@95.217.43.189:14956,f52b6ca356060842431aa96392af4e9fdeaec436@67.209.53.70:26656,0add711ee2dcedcfb4c575aa1ace3f4995c8d731@170.64.218.141:26090"
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" \
       -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.gaia/config/config.toml
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.0025uatom"|g' $HOME/.gaia/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.gaia/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.gaia/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.gaia/config/app.toml 
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.gaia/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.gaia/config/app.toml
  
sed -i.bak -e "s%:26658%:${CUSTOM_PORT}658%g;
s%:26657%:${CUSTOM_PORT}657%g;
s%:26656%:${CUSTOM_PORT}656%g;
s%:6060%:${CUSTOM_PORT}060%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${CUSTOM_PORT}56\"%;
s%:26660%:${CUSTOM_PORT}660%g" $HOME/.gaia/config/config.toml

sed -i.bak -e "s%:1317%:${CUSTOM_PORT}317%g;
s%:8080%:${CUSTOM_PORT}080%g;
s%:9090%:${CUSTOM_PORT}090%g;
s%:9091%:${CUSTOM_PORT}091%g;
s%:8545%:${CUSTOM_PORT}545%g;
s%:8546%:${CUSTOM_PORT}546%g" $HOME/.gaia/config/app.toml

sudo tee /etc/systemd/system/gaiad.service > /dev/null <<EOF
[Unit]
Description=Cosmos node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.gaia
ExecStart=$(which gaiad) start --home $HOME/.gaia
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

print "Downloading snapshot..."
curl -L https://snapshots.kjnodes.com/cosmoshub/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.gaia

sudo systemctl daemon-reload
sudo systemctl enable gaiad
sudo systemctl restart gaiad

print "✅ Setup complete. Use 'journalctl -u gaiad -f -o cat' to view logs"
