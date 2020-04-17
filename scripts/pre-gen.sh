#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

export genesis_key

usage() {
    echo "OPTIONS:"
    echo "  [--encrypted]  Encrpy the generated genesis key"
}

base_dir="base-dir"
client_dir=$base_dir/"client"

gen_genesis_key() {
    tezos_client="base-dir/tezos-client"
    chmod +x "$tezos_client"
    if [[ $encrypted_flag == "true" ]]; then
        "$tezos_client" -d "$client_dir" gen keys genesis --encrypted --force
    else
        "$tezos_client" -d "$client_dir" gen keys genesis --force
    fi
    genesis_key="$("$tezos_client" -d "$client_dir" show address genesis \
      | sed --quiet --expression='s/^.*Public Key: //p'
    )"
    echo "Genesis key:"
    echo "$genesis_key" | tee "base-dir/genesis_key.txt"
    echo

}

write_config() {
    cat > "$node_dir/config.json" <<- EOM
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




encrypted_flag=false
while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --encrypted)
            encrypted_flag=true
            shift
            ;;
        *)
            echo "Unexpected option \"$1\"."
            usage
            exit 1
            ;;
    esac
done

gen_genesis_key
