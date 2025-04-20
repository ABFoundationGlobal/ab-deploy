#!/usr/bin/env bash

set -eu

# Use this script to download the latest AB release binary.
# Use USE_AB_BLOCKCHAIN_VERSION to specify a specific release version.
#   Example: USE_AB_BLOCKCHAIN_VERSION=v1.8.26 ./ab.sh

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
color "37" "AB Blockchain Installer"

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
ab_root_path="/data/ab"
ab_chain_path="${ab_root_path}/${abchain}"
ab_chain_network_path="${ab_chain_path}/${networkname}"
mkdir -p ${ab_chain_network_path}
work_size=$(du -s ${ab_chain_network_path} | awk '{print $1}')
# if less then 100 M, then check disk available space
if [[ ${work_size} -lt 102400 ]]; then
  # first time, check disk available space
  DiskSize=$(df -P ${ab_chain_network_path} | awk 'NR==2 {print $4}')
  MemTotal=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
  # 2 GB = 2097152 KB
  # 4 GB = 4194304 KB
  # 8 GB = 8388608 KB
  # 10GB = 10485760 KB = 10737418240 bytes
  # 20GB = 20971520 KB = 21474836480 bytes
  # 50GB = 52428800 KB = 53687091200 bytes
  # 100GB = 104857600 KB = 107374182400 bytes
  # 200GB = 209715200 KB = 214748364800 bytes
  DiskSizeGB=$((${DiskSize}/1024/1024))
  MemTotalGB=$((${MemTotal}/1024/1024))
  color "" "Avail disk space is ${DiskSize} KB (${DiskSizeGB} GB)."
  color "" "Total memory is ${MemTotal} KB (${MemTotalGB} GB)"
  if [[ ${networkname} == "mainnet" ]]; then
    # use 100000000 instead of 104857600
    if [[ ${DiskSize} -lt 100000000 ]]; then
        color 31 'Disk space is less than 100 GB (104857600 KB)'
        exit 0
    fi
  else
    # use 200000000 instead of 209715200, update for testnet 2021
    if [[ ${DiskSize} -lt 100000000 ]]; then
        color 31 'Disk space is less than 200 GB (209715200 KB)'
        exit 0
    fi
  fi
  # use 8000000 instead of 8388608
  if [[ ${MemTotal} -lt 7200000 ]]; then
      color 31 'Total memory is less than 8 GB (8388608 KB)'
      exit 0
  fi
else
 color "" "Detected current is an upgrade, ignore the system info check."
fi

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

# stop all ab family programs, only one node can run at the same time
sudo supervisorctl stop newchain newchainguard abiot abiotguard abiottestnet abiottestnetguard abcore abcoretestnet > /dev/null 2>&1 || true

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
    # exit 0 # not now
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

################## AB IoT Guard ##################
if [[ "$abchain" == "abiot" ]]; then
  color "" "################## AB IoT Guard ##################"
  # install AB IoT Guard
  function get_abiot_guard_version() {
      if [[ -n ${USE_AB_GUARD_VERSION:-} ]]; then
          readonly guard_reason="specified in \$USE_AB_GUARD_VERSION"
          readonly newchain_guard_version="${USE_AB_GUARD_VERSION}"
      else
          # Find the latest AB IoT Guard version available for download.
          readonly guard_reason="automatically selected latest available version"
          newchain_guard_version="$(curl -s "https://api.github.com/repos/newtonproject/newchain-guard/releases/latest" | grep '"tag_name":' | awk -F '"' '{print $4}')" || (color "31" "Get ${abchainname} Guard latest version error." && exit 1)
          readonly newchain_guard_version
      fi
  }

  get_abiot_guard_version
  color "37" "Latest ${abchainname} Guard version is ${newchain_guard_version}."

  newchian_guard_network_file="guard.${newchain_guard_version}"
  if [[ -f ${ab_chain_network_path}/bin/${newchian_guard_network_file} ]]; then
      color "32" "${abchainname} Guard is up to date."
      if [[ "$(realpath ${ab_chain_network_path}/bin/guard)" != "${ab_chain_network_path}/bin/${newchian_guard_network_file}" ]]; then
        ln -sf "${newchian_guard_network_file}" ${ab_chain_network_path}/bin/guard
        color "37" "Updated ${abchainname} Guard binary link."
        # supervisorctl restart ${ab_program_name}guard || {
        #   color "31" "Failed to restart ${abchainname} guard by supervisor."
        #   exit 1
        # }
      fi

      # exit 0 # not now
  fi

  guard_file="newchain-guard-${newchain_guard_version}"
  function download_guard_bin() {
    color "34" "Downloading NewChainGuard@${newchain_guard_version} binary to ${guard_file}"
    github_url="https://github.com/newtonproject/newchain-guard/releases/download/${newchain_guard_version}/${guard_file}"
    color "33" "Downloading from ${github_url}"
    curl -L "${github_url}" -o $guard_file || {
      color "31" "Failed to download the NewChain Guard binary."
      exit 1
    }
  }

  curl --silent -L "https://github.com/newtonproject/newchain-guard/releases/download/${newchain_guard_version}/${guard_file}.sha256" -o "${guard_file}.sha256"
  if test -f "$guard_file"; then
    sha256sum_res=$(shasum -a 256 -c "${guard_file}.sha256" | awk '{print $2}')
    if [ "$sha256sum_res" != "OK" ]; then
      download_guard_bin
    fi
  else
    download_guard_bin
  fi


  color "37" "Trying to verify the downloaded ${abchainname} Guard binary file..."
  sha256sum_res=$(shasum -a 256 -c "${guard_file}.sha256" | awk '{print $2}')
  if [ "$sha256sum_res" == "OK" ]; then
    color "32" "Verify $guard_file $sha256sum_res, checksum match."
  else
    color "41" "Verify $guard_file $sha256sum_res, checksum did NOT match."
    exit 1
  fi

  chmod +x $guard_file
  cp $guard_file ${ab_chain_network_path}/bin/${newchian_guard_network_file}
  ln -sf "${newchian_guard_network_file}" ${ab_chain_network_path}/bin/guard || {
    color "31" "Failed to link $newchian_guard_network_file to guard."
    exit 1
  }
  color "37" "Updated ${abchainname} Guard binary link."
fi

################## deploy files ##################
# AB Deploy file
color "" "################## deploy config files ##################"
function get_ab_deploy_version() {
    if [[ -n ${USE_AB_DEPLOY_VERSION:-} ]]; then
        readonly deploy_reason="specified in \$USE_AB_DEPLOY_VERSION"
        readonly ab_deploy_version="${USE_AB_DEPLOY_VERSION}"
    else
        # Find the latest AB nodes version available for download.
        readonly deploy_reason="automatically selected latest available version"
        ab_deploy_version="$(curl -s "https://api.github.com/repos/ABFoundationGlobal/ab-deploy/releases/latest" | grep '"tag_name":' | awk -F '"' '{print $4}')" || (color "31" "Get ${abname} deploy latest version error." && exit 1)
        # if [[ "$networkname" == "testnet" ]]; then
        #   ab_deploy_version="$(curl -s "https://api.github.com/repos/ABFoundationGlobal/ab-deploy/tags" | grep '"name":' | head -n 1 | awk -F '"' '{print $4}')" || (color "31" "Get ${abname} deploy latest version error." && exit 1)
        # fi
        readonly ab_deploy_version
    fi
}

get_ab_deploy_version
color "37" "Latest ${abname} deploy version is $ab_deploy_version."



# get deploy files
deploy_file="${abchain}-${networkname}-${ab_deploy_version}.tar.gz"
function download_deploy_file() {
  color "34" "Downloading ${abname} deploy file of ${ab_deploy_version} to ${deploy_file} (${deploy_reason})"
  github_url="https://github.com/ABFoundationGlobal/ab-deploy/releases/download/${ab_deploy_version}/${deploy_file}"
  color "33" "Downloading from ${github_url}"
  curl -L "${github_url}" -o "${deploy_file}" || {
    color "31" "Failed to download the ${abname} deploy file."
    exit 1
  }
}

curl --silent -L "https://github.com/ABFoundationGlobal/ab-deploy/releases/download/${ab_deploy_version}/${deploy_file}.sha256" -o "${deploy_file}.sha256"
# TODO: add gpg
if test -f "$deploy_file"; then
  sha256sum_deploy_res=$(shasum -a 256 -c "${deploy_file}.sha256" | awk '{print $2}')
  if [ "$sha256sum_deploy_res" != "OK" ]; then
    download_deploy_file
  fi
else
  download_deploy_file
fi

color "37" "Trying to verify the installation file..."
# TODO: add gpg
sha256sum_deploy_res=$(shasum -a 256 -c "${deploy_file}.sha256" | awk '{print $2}')
if [ "$sha256sum_deploy_res" == "OK" ]; then
    color "32" "Verify $deploy_file $sha256sum_deploy_res, checksum match."
else
    color "41" "Verify $deploy_file $sha256sum_deploy_res, checksum did NOT match."
    exit 1
fi
# check current config files
current_time=$(date +"%Y%m%d%H%M%S")
if [[ -x ${ab_chain_network_path}/conf/node.toml ]]; then
    mv ${ab_chain_network_path}/conf/node.toml ${ab_chain_network_path}/conf/node.${current_time}.toml
fi
if [[ -x ${ab_chain_network_path}/conf/guard.toml ]]; then
    mv ${ab_chain_network_path}/conf/guard.toml ${ab_chain_network_path}/conf/guard.${current_time}.toml
fi
# force extract deploy files
tar zxf "$deploy_file" -C ${ab_root_path}  || {
  color "31" "Failed to extract $deploy_file to ${ab_root_path}."
  exit 1
}
chown -R $sudo_user ${ab_root_path}
sed -i "s/run_as_username/$sudo_user/g" ${ab_chain_network_path}/conf/node.toml

if [[ ! -x ${ab_chain_network_path}/nodedata/geth/ ]]; then
  color "37" "Trying to init the ${abname} node data directory..."
  ${ab_chain_network_path}/bin/geth --config ${ab_chain_network_path}/conf/node.toml --datadir ${ab_chain_network_path}/nodedata init ${ab_chain_network_path}/share/${abchain}${networkname}.json  || {
    color "31" "Failed to init the ${abname} node data directory."
    exit 1
  }
else
  # force re-init nodedata
  color "37" "Trying to re-init the ${abname} node data directory..."
  ${ab_chain_network_path}/bin/geth --config ${ab_chain_network_path}/conf/node.toml --datadir ${ab_chain_network_path}/nodedata init ${ab_chain_network_path}/share/${abchain}${networkname}.json  || {
    color "31" "Failed to re-init the ${abname} node data directory."
    exit 1
  }
fi

chown -R $sudo_user:$sudo_user ${ab_chain_network_path}

color "37" "Trying to check and configure supervisor..."

sed -i "s/run_as_username/$sudo_user/g" ${ab_chain_network_path}/supervisor/${ab_program_name}.conf || {
  color "31" "Failed to update ${abname} supervisor config file."
  exit 1
}
cp ${ab_chain_network_path}/supervisor/${ab_program_name}.conf /etc/supervisor/conf.d/ || {
  color "31" "Failed to copy ${abname} supervisor config file."
  exit 1
}

if [[ "$abchain" == "abiot" ]]; then
  sed -i "s/run_as_username/$sudo_user/g" ${ab_chain_network_path}/supervisor/${ab_program_name}guard.conf || {
    color "31" "Failed to update ${abname} supervisor config file."
    exit 1
  }
  cp ${ab_chain_network_path}/supervisor/${ab_program_name}guard.conf /etc/supervisor/conf.d/ || {
    color "31" "Failed to copy ${abname} supervisor config file."
    exit 1
  }
fi

supervisorctl update || {
  color "31" "Failed to exec supervisorctl update."
  exit 1
}

# force sleep 3s, waiting AB nodes and guard to be stared
sleep 3

abstatus="$(supervisorctl status ${ab_program_name} | awk '{print $2}')"
if [[ "${abstatus}" != "RUNNING" && "${abstatus}" != "STARTING" ]]; then
  supervisorctl start ${ab_program_name} || {
    color "31" "Failed to exec supervisorctl start ${ab_program_name}."
    exit 1
  }
fi

if [[ "$abchain" == "abiot" ]]; then
  abiotguardstatus="$(supervisorctl status ${ab_program_name}guard | awk '{print $2}')"
  if [[ "${abiotguardstatus}" != "RUNNING" && "${abiotguardstatus}" != "STARTING" ]]; then
    supervisorctl start ${ab_program_name}guard || {
      color "31" "Failed to exec supervisorctl start ${ab_program_name}guard."
      exit 1
    }
  fi
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

color "32" "${abname} has been SUCCESSFULLY deployed!"
color "32" "$LOGO"

supervisorctl tail -f ${ab_program_name} stderr
