#!/bin/bash

set -eu

# Use this script with Makefile.
#   Example: ./build.sh <tagname> <abchain> <networkname>

function color() {
    # Usage: color "31;5" "string"
    # Some valid values for color:
    # - 5 blink, 1 strong, 4 underlined
    # - fg: 31 red,  32 green, 33 yellow, 34 blue, 35 purple, 36 cyan, 37 white
    # - bg: 40 black, 41 red, 44 blue, 45 purple
    printf '\033[%sm%s\033[0m\n' "$@"
}

if [ $# -eq 3 ]; then
  version="$1"
  abchain="$2"
  networkname="$3"
else
  color "31" "No args found or args len error, please run with 'make'."
fi

case "$abchain" in
  abiot)
    abchainname="AB IoT"
    ;;
  abcore)
    abchainname="AB Core"
    ;;
  *)
    echo "❌ Unknown chain: $abchain"
    exit 1
    ;;
esac

color "" "Current Network is ${abchainname} ${networkname}"

version="$1"
color "" "Current version is ${version}"

mkdir -p build/
cd build/
tar czvf ${abchain}-${networkname}-${version}.tar.gz -C ../ ${abchain}/${networkname}
shasum -a 256 ${abchain}-${networkname}-${version}.tar.gz > ${abchain}-${networkname}-${version}.tar.gz.sha256

# # update ab.sh
# cp ../../../ab.sh ab.sh
# perl -i -pe "s/ab_deploy_latest_version=.*/ab_deploy_latest_version='${version}'/" ab.sh
# perl -i -pe "s/default_ab_chain=.*/default_ab_chain='${abchain}'/" ab.sh
# perl -i -pe "s/default_networkname=.*/default_networkname='${networkname}'/" ab.sh

# # update ab-mine.sh
# cp ../../../ab-mine.sh ab-mine.sh
# perl -i -pe "s/default_ab_chain=.*/default_ab_chain='${abchain}'/" ab-mine.sh
# perl -i -pe "s/default_networkname=.*/default_networkname='${networkname}'/" ab-mine.sh