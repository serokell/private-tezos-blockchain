#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

script_args=()

usage () {
    echo "This script launches baker/node instances inside a Docker container for a Tezos private network"
    echo "COMMANDS:"
    echo "  run-all  --genesis-key <public-key>"
}

if [[ $# -eq 0 || $1 == "--help" ]]; then
    usage
    exit 1
fi

while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --genesis-key )
            genesis_key="$2"
            shift 2
            ;;
        * )
            script_args+=("$1")
            shift
            ;;
    esac
done

if [[ -z ${genesis_key:-} ]]; then
    echo "\"--genesis-key\" wasn't provided."
    exit_flag="true"
fi

docker build -t ubuntu-tezos .

docker volume create ubuntu-tezos-volume

docker run --network host -v ubuntu-tezos-volume:/base-dir \
    -i -t ubuntu-tezos fetch-binaries \
    --base-chain carthagenet \
    --genesis-key $genesis_key

docker run --network host \
    --expose 8733 -v ubuntu-tezos-volume:/base-dir \
    -i -t ubuntu-tezos start-baker \
    --net-address "" \
    --net-addr-port 8733 \
    --rpc-address "" \
    --rpc-addr-port 8732
