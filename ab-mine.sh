#!/bin/bash

default_ab_chain="abcore"
default_networkname='mainnet'

cd ${ab_chain_network_path}/

function color() {
    # Usage: color "31;5" "string"
    # Some valid values for color:
    # - 5 blink, 1 strong, 4 underlined
    # - fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
    # - bg: 40 black, 41 red, 44 blue, 45 purple
    printf '\033[%sm%s\033[0m\n' "$@"
}
color "37" ""

# handle network
abchain="${1:-$default_ab_chain}"
networkname="${2:-$default_networkname}"

abchain=$(echo "$abchain" | tr '[:upper:]' '[:lower:]')
networkname=$(echo "$networkname" | tr '[:upper:]' '[:lower:]')

# Parse chain type
case "$abchain" in
  abcore | core)
    abchain="abcore"
    ;;
  abiot | iot)
    abchain="abiot"
    ;;
  *)
    echo -e "❌ Unsupported chain: $abchain"
    exit 1
    ;;
esac

# Parse network type
case "$networkname" in
  mainnet | main)
    networkname="mainnet"
    ;;
  testnet | test)
    networkname="testnet"
    ;;
  *)
    echo -e "❌ Unsupported network: ${networkname}"
    exit 1
    ;;
esac

case "$abchain" in
  abiot)
    abchainname="AB IoT"
    ;;
  abcore)
    abchainname="AB Core"
    ;;
  *)
    echo "❌ Unknown chain: ${abchain}"
    exit 1
    ;;
esac

color "32" "Current network is ${abchainname} ${networkname}"

current_user="${SUDO_USER:-$(whoami)}"
color "32" "Current user is $current_user"

abname="${abchain} ${networkname}"
ab_root_path="/data"
ab_chain_path="${ab_root_path}/${abchain}"
ab_chain_network_path="${ab_chain_path}/${networkname}"

if [[ $(${ab_chain_network_path}/bin/geth attach --exec eth.syncing ${ab_chain_network_path}/nodedata/geth.ipc) != "false" ]]; then
  color "31" "Please wait until your node synchronization is complete"
  exit 0
else
  color "37" "Your node has been synchronized"
fi

# Trying to get current miner address if exits
address=$(${ab_chain_network_path}/bin/geth attach ${ab_chain_network_path}/nodedata/geth.ipc --exec eth.coinbase | sed 's/\"//g')
if [[ ${address} != 0x* || ${#address} < 42 ]]; then
  # Account
  color "" "Create new password for your miner's keystore."
  color "" "Your new account is locked with a password. Please give a password. Do not forget this password."
  echo -n "Password: "
  read -s password0
  echo
  echo -n "Repeat password: "
  read -s password1
  echo
  if [[ ${password0}  != ${password1} ]]; then
    color "31" "Passwords do not match"
    exit 0
  fi
  if [[ ${password0} == "" ]]; then
    color "31" "Passwords is empty"
    exit 0
  fi
  if ( echo ${password0} | grep -q ' ' ); then
    color "31" "Passwords has space"
    exit 0
  fi
  echo ${password0} > ${ab_chain_network_path}/password.txt
  chown $current_user:$current_user ${ab_chain_network_path}/password.txt

  # ${ab_chain_network_path}/bin/geth --config ${ab_chain_network_path}/conf/node.toml account new --password ${ab_chain_network_path}/password.txt
  address=$(sudo -u ${current_user} ${ab_chain_network_path}/bin/geth --config ${ab_chain_network_path}/conf/node.toml account new --password ${ab_chain_network_path}/password.txt | grep "Public address" | awk '{print $6}')
  echo "you miner address is: |${address}|"
  if [[ ${address} != 0x* || ${#address} < 42 ]]; then
    color "31" "address len error"
    exit 1
  fi
  color "32" "Your miner address keystore is under ${ab_chain_network_path}/nodedata， please backup it."
fi

current_time=$(date +"%Y%m%d%H%M%S")
# node.toml: disable rpc
cp ${ab_chain_network_path}/conf/node.toml ${ab_chain_network_path}/conf/node.bak.${current_time}.toml
sudo perl -i -pe "s,HTTPHost.*,HTTPHost = \"\"," ${ab_chain_network_path}/conf/node.toml
sudo perl -i -pe "s,WSHost.*,WSHost = \"\"," ${ab_chain_network_path}/conf/node.toml

# Supervisor: update command to enable mine
ab_program_name="${abchain}"
if [[ "$networkname" == "testnet" ]]; then
  ab_program_name="${abchain}${networkname}"
fi
cp /etc/supervisor/conf.d/${ab_program_name}.conf ${ab_chain_network_path}/supervisor/${ab_program_name}.bak.${current_time}.conf
sudo sed  -i "s,command=.*,command=${ab_chain_network_path}/bin/geth --config ${ab_chain_network_path}/conf/node.toml --mine --unlock ${address} --password ${ab_chain_network_path}/password.txt," /etc/supervisor/conf.d/${ab_program_name}.conf

# Guard: disable AB IoT guard
if [[ "$networkname" == "testnet" ]]; then
  sudo mv /etc/supervisor/conf.d/${ab_program_name}guard.conf ${ab_chain_network_path}/supervisor/${ab_program_name}uard.bak.${current_time}.conf
fi

sudo supervisorctl update

# get IPs from ifconfig and dig
#LOCALIP=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | cut -d':' -f2)
IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

color "37" "Copy the following information and share it with other mining nodes: "
color "32" "
Address: ${address}
IP: ${IP}
"
