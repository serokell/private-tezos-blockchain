#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

usage () {
    echo "--write-config --genesis-key <public-key>"
    echo "--peer <ip address>"
}

write_config() {
    cat > "base-dir/node/config.json" <<- EOM
{
    "p2p": {},
    "network": {
        "genesis": {
            "timestamp": "2019-11-28T13:02:13Z",
            "block": "BLockGenesisGenesisGenesisGenesisGenesisd6f5afWyME7",
            "protocol": "PtYuensgYBb3G3x1hLLbCmcav8ue8Kyd2khADcL5LsT5R1hcXex"
        },
        "genesis_parameters": {
            "values": {
            "genesis_pubkey": "$genesis_key"
            }
        },
        "chain_name": "TEZOS_ALPHANET_CARTHAGE_2019-11-28T13:02:13Z",
        "old_chain_name": "TEZOS_ALPHANET_CARTHAGE_2019-11-28T13:02:13Z",
        "incompatible_chain_name": "INCOMPATIBLE",
        "sandboxed_chain_name": "SANDBOXED_TEZOS",
        "default_bootstrap_peers": []
    }
}
EOM
}

write_docker_env() {
    cat > "tezos-docker.env" <<- EOM
{
    network=host
    volume=ubuntu-tezos-volume:/base-dir
    peer="$peer"
    genesis_key="$genesis_key"
    test_ver=2
}
EOM
}

genesis_key=""
peer=""

while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --genesis-key)
            genesis_key="$2"
            shift 2
            ;;
        --peer)
            peer="$2"
            shift 2
            ;;
        *)
            echo "Unexpected option \"$1\"."
            usage
            exit 1
            ;;
    esac
done

exit_flag="false"

if [[ -z ${genesis_key:-} ]]; then
    echo "\"--genesis-key\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${peer:-} ]]; then
    echo "\"--peer\" wasn't provided."
    exit_flag="true"
fi

[[ $exit_flag == "true" ]] && exit 1

write_config
write_docker_env
