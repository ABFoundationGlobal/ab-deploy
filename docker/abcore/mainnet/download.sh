#!/usr/bin/env bash
set -euo pipefail

abchain="${ABCHAIN:-abcore}"
network="${NETWORK:-mainnet}"

if [ -n "${USE_AB_BLOCKCHAIN_VERSION:-}" ]; then
  ab_version="${USE_AB_BLOCKCHAIN_VERSION}"
else
  ab_version="$(curl -s "https://api.github.com/repos/ABFoundationGlobal/${abchain}/releases/latest" \
    | grep '"tag_name":' | awk -F '"' '{print $4}')"
fi

if [ -n "${USE_AB_DEPLOY_VERSION:-}" ]; then
  ab_deploy_version="${USE_AB_DEPLOY_VERSION}"
else
  ab_deploy_version="$(curl -s "https://api.github.com/repos/ABFoundationGlobal/ab-deploy/releases/latest" \
    | grep '"tag_name":' | awk -F '"' '{print $4}')"
fi

geth_file="geth-${ab_version}"
deploy_file="${abchain}-${network}-${ab_deploy_version}.tar.gz"

echo "Downloading ${geth_file}"
curl -fL "https://github.com/ABFoundationGlobal/${abchain}/releases/download/${ab_version}/${geth_file}" \
  -o "/opt/ab/${geth_file}"
curl -fL "https://github.com/ABFoundationGlobal/${abchain}/releases/download/${ab_version}/${geth_file}.sha256" \
  -o "/opt/ab/${geth_file}.sha256"

expected_geth_sha="$(awk '{print $1}' "/opt/ab/${geth_file}.sha256")"
actual_geth_sha="$(sha256sum "/opt/ab/${geth_file}" | awk '{print $1}')"
test "${expected_geth_sha}" = "${actual_geth_sha}"

chmod +x "/opt/ab/${geth_file}"
ln -sf "/opt/ab/${geth_file}" /usr/local/bin/geth

echo "Downloading ${deploy_file}"
curl -fL "https://github.com/ABFoundationGlobal/ab-deploy/releases/download/${ab_deploy_version}/${deploy_file}" \
  -o "/opt/ab/${deploy_file}"
curl -fL "https://github.com/ABFoundationGlobal/ab-deploy/releases/download/${ab_deploy_version}/${deploy_file}.sha256" \
  -o "/opt/ab/${deploy_file}.sha256"

expected_deploy_sha="$(awk '{print $1}' "/opt/ab/${deploy_file}.sha256")"
actual_deploy_sha="$(sha256sum "/opt/ab/${deploy_file}" | awk '{print $1}')"
test "${expected_deploy_sha}" = "${actual_deploy_sha}"

echo "${ab_version}" > /opt/ab/ABCORE_VERSION
echo "${ab_deploy_version}" > /opt/ab/ABDEPLOY_VERSION
echo "${deploy_file}" > /opt/ab/DEPLOY_FILE