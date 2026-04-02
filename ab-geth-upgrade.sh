#!/usr/bin/env bash

set -eu

# Use this script to upgrade the latest AB geth binary only.
# It does not update genesis, config files, or nodedata.
# Use USE_AB_BLOCKCHAIN_VERSION to specify a specific release version.
#   Example: USE_AB_BLOCKCHAIN_VERSION=v1.8.26 ./ab-geth-upgrade.sh abcore mainnet

default_ab_chain="abcore"
default_networkname='mainnet'

function color() {
    # Usage: color "31;5" "string"
    # Some valid values for color:
    # - 5 blink, 1 strong, 4 underlined
    # - fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
    # - bg: 40 black, 41 red, 44 blue, 45 purple
    printf '\033[%sm%s\033[0m\n' "$@"
}
color "37" "AB Blockchain Upgrader"

system=""
case "$OSTYPE" in
darwin*) system="darwin" ;;
linux*) system="linux" ;;
msys*) system="windows" ;;
cygwin*) system="windows" ;;
*) exit 1 ;;
esac
readonly system

if [ "$system" != "linux" ]; then
    color "31" "Not support's system, please use Ubuntu 18.04 LTS."
    exit 1
fi
color "37" "Current system is $system"

# Check run as root
if [ $EUID -ne 0 ]; then
   color "31" "Run this script with 'sudo $0'"
   exit 1
fi

# get current user
sudo_user="$SUDO_USER"
if [ "$sudo_user" == "" ]; then
  sudo_user="$(whoami)"
fi

color "33" "Current sudo user is $sudo_user"


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

abname="${abchain} ${networkname}"

color "32" "Current network is ${abchainname} ${networkname}"

################## system info ##################
color "37" "Trying to check system info..."
root_path="/data"
ab_chain_path="${root_path}/${abchain}"
ab_chain_network_path="${ab_chain_path}/${networkname}"
mkdir -p ${ab_chain_network_path}
color "" "Detected current is an upgrade, ignore the system info check."

type supervisorctl &> /dev/null || (apt update && apt install -y supervisor) || {
  color "31" "Failed to install supervisor."
  exit 1
}

################## work directory ##################
color "37" "Trying to init the work directory..."
mkdir -p ${ab_chain_network_path}/bin/
chown -R $sudo_user ${ab_chain_network_path}
ab_program_name="${abchain}"
if [[ "$networkname" == "testnet" ]]; then
  ab_program_name="${abchain}${networkname}"
fi

color "" "################## ${abname} ##################"
function get_ab_version() {
    if [[ -n ${USE_AB_BLOCKCHAIN_VERSION:-} ]]; then
        readonly reason="specified in \$USE_AB_BLOCKCHAIN_VERSION"
        readonly ab_version="${USE_AB_BLOCKCHAIN_VERSION}"
    else
        # Find the latest AB nodes version available for download.
        readonly reason="automatically selected latest available version"
        ab_version="$(curl -s "https://api.github.com/repos/ABFoundationGlobal/${abchain}/releases/latest" | grep '"tag_name":' | awk -F '"' '{print $4}')" || (color "31" "Get ${abname} latest version error." && exit 1)
        # if [[ "$networkname" == "testnet" ]]; then
        #   ab_version="$(curl -s "https://api.github.com/repos/ABFoundationGlobal/${abchain}/tags" | grep '"name":' | head -n 1 | awk -F '"' '{print $4}')" || (color "31" "Get ${abname} latest version error." && exit 1)
        # fi
        readonly ab_version
    fi
}

get_ab_version
color "37" "Latest ${abname} version is $ab_version."

ab_version_file="geth.${ab_version}"

if [[ -f ${ab_chain_network_path}/bin/${ab_version_file} ]]; then
    color "32" "${abchainname} ${networkname} is up to date."
    if [[ "$(realpath ${ab_chain_network_path}/bin/geth)" != "${ab_chain_network_path}/bin/${ab_version_file}" ]]; then
      ln -sf "${ab_version_file}" ${ab_chain_network_path}/bin/geth
      color "37" "Updated ${abname} binary link."
      supervisorctl restart ${ab_program_name} || {
        color "31" "Failed to restart ${ab_program_name} by supervisor."
        exit 1
      }
    fi
    exit 0 # for upgrade, exit
fi

file="geth"
geth_file="geth-${ab_version}"
function download_geth_bin() {
  color "34" "Downloading ${abname} binary@${ab_version} to ${file} (${reason})"
  github_url="https://github.com/ABFoundationGlobal/${abchain}/releases/download/${ab_version}/${geth_file}"
  color "33" "Downloading from ${github_url}"
  curl -L "${github_url}" -o "${geth_file}" || {
    color "31" "Failed to download the ${abname} binary."
    exit 1
  }
}

curl --silent -L "https://github.com/ABFoundationGlobal/${abchain}/releases/download/${ab_version}/${geth_file}.sha256" -o "${geth_file}.sha256"
# TODO: add gpg
if test -f "$geth_file"; then
  sha256sum_res=$(shasum -a 256 -c "${geth_file}.sha256" | awk '{print $2}')
  if [ "$sha256sum_res" != "OK" ]; then
    download_geth_bin
  fi
else
  download_geth_bin
fi

color "37" "Trying to verify the downloaded ${abname} binary file..."
sha256sum_res=$(shasum -a 256 -c "${geth_file}.sha256" | awk '{print $2}')
if [ "$sha256sum_res" == "OK" ]; then
  color "32" "Verify $geth_file $sha256sum_res, checksum match."
else
  color "41" "Verify $geth_file $sha256sum_res, checksum did NOT match."
  exit 1
fi

chmod +x $geth_file
cp $geth_file ${ab_chain_network_path}/bin/${ab_version_file}
ln -sf "${ab_version_file}" ${ab_chain_network_path}/bin/geth || {
  color "31" "Failed to link geth to $ab_version_file."
  exit 1
}
color "37" "Updated ${abname} binary link."


# restart ab node programs
supervisorctl restart ${ab_program_name} > /dev/null 2>&1 || {
  color "31" "Failed to restart ${ab_program_name} by supervisor."
  exit 1
}

sleep 3

abstatus="$(supervisorctl status ${ab_program_name} | awk '{print $2}')"
if [[ "${abstatus}" != "RUNNING" && "${abstatus}" != "STARTING" ]]; then
  color "31" "${ab_program_name} is not running after upgrade, current status: ${abstatus}"
  exit 1
fi

LOGO=$(
      cat <<-'END'
                             $$$$$$$
                             $:::::$ 
                $$$$$$$$$$$$$$:::::$$$$$$$$  
               $:::::::::::::::::::::::::::$  
              $:::::::::::$$$$$$$$$$$$$:::::$ 
             $:::::$$:::::$            $:::::$
            $:::::$ $:::::$             $:::::$
           $:::::$  $:::::$            $:::::$
    $$$$$$$:::::$$$$$:::::$$$$$$$$$$$$$:::::$ 
    $$::::::::::::::::::::::::::::::::::::$$  
    $$$$$:::::$$$$$$$:::::$$$$$$$$$$$$$:::::$ 
       $:::::$      $:::::$            $:::::$
      $:::::$       $:::::$             $:::::$
     $:::::$        $:::::$             $:::::$
    $:::::$         $:::::$             $:::::$
   $:::::$          $:::::$            $:::::$
  $:::::$           $:::::$$$$$$$$$$$$$:::::$ 
 $:::::$            $::::::::::::::::::::::$  
$$$$$$$             $$$$$$$$$$:::::$$$$$$$$
                             $:::::$
                             $$$$$$$  
END
  )

color "32" "${abname} nodes has been SUCCESSFULLY upgraded!"
color "32" "$LOGO"

supervisorctl tail -f ${ab_program_name} stderr
