#!/usr/bin/env bash
set -euo pipefail

mode="${1:-init}"

deploy_file="$(cat /opt/ab/DEPLOY_FILE)"
deploy_version="$(cat /opt/ab/ABDEPLOY_VERSION)"
network_root="/data/abcore/mainnet"
deploy_marker="${network_root}/.abdeploy-version"
chaindata_dir="${network_root}/nodedata/geth/chaindata"

mkdir -p /data
mkdir -p "${network_root}"

need_extract="0"
if [ ! -f "${network_root}/share/abcoremainnet.json" ] || \
   [ ! -f "${network_root}/conf/node.toml" ] || \
   [ ! -f "${deploy_marker}" ] || \
   [ "$(cat "${deploy_marker}" 2>/dev/null || true)" != "${deploy_version}" ]; then
  need_extract="1"
fi

if [ "${need_extract}" = "1" ]; then
  echo "Extracting ${deploy_file} to /data"
  tar zxf "/opt/ab/${deploy_file}" -C /data
  printf '%s\n' "${deploy_version}" > "${deploy_marker}"
fi

test -f "${network_root}/conf/node.toml"
test -f "${network_root}/share/abcoremainnet.json"

mkdir -p "${network_root}/nodedata"

if [ ! -d "${chaindata_dir}" ]; then
  echo "Initializing genesis into ${network_root}/nodedata"
  /usr/local/bin/geth \
    --config "${network_root}/conf/node.toml" \
    --datadir "${network_root}/nodedata" \
    init "${network_root}/share/abcoremainnet.json"
fi

if [ "${mode}" = "run" ]; then
  exec /usr/local/bin/geth \
    --config "${network_root}/conf/node.toml" \
    --datadir "${network_root}/nodedata"
fi
