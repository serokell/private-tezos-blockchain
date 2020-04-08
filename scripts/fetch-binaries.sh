#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER="Y"

gen_genesis_key() {
    # download tezos-client if not presented to generate new public key
    if [[ ! -f $base_dir/tezos-client ]]; then
        wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/tezos-client \
        -P "$base_dir/"
    fi
    tezos_client="$base_dir/tezos-client"
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
    echo "$genesis_key" | tee "$base_dir/genesis_key.txt"
    echo

}

usage() {
    echo "This script will compile the tezos binaries from scratch using"
    echo "a newly generated or provided public key."
    echo "OPTIONS:"
    echo "  --base-dir <filepath>. Base directory for compiled binaries"
    echo "    and genesis account."
    echo "  [--genesis-key <public-key>]. Genesis public key used for binary compiling."
    echo "    If not provided, this script will generate a new genesis public key."
    echo "  [--base-chain <babylonnet | carthagenet>]. Define base chain for your private"
    echo "    blockchain. Default is 'carthagenet'."
    echo "  [--encrypted]. Define whether the generated genesis secret key will be encrypted"
}

if [[ $# -eq 0 || $1 == "--help" ]]; then
    usage
    exit 1
fi

encrypted_flag=false
genesis_key=""
base_chain="carthagenet"
while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --base-dir | -d )
            base_dir="$2"
            shift 2
            ;;
        --genesis-key)
            genesis_key="$2"
            shift 2
            ;;
        --encrypted)
            encrypted_flag=true
            shift
            ;;
        --base-chain )
            base_chain="$2"
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

if [[ -z ${base_dir:-} ]]; then
    echo "\"--base-dir\" wasn't provided."
    exit_flag="true"
fi

[[ $exit_flag == "true" ]] && exit 1

mkdir -p "$base_dir"
client_dir="$base_dir/client"
mkdir -p "$client_dir"
node_dir="$base_dir/node"
mkdir -p "$node_dir"

[[ -z $genesis_key ]] && gen_genesis_key

wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/tezos-node \
     -P "$base_dir/"
case "$base_chain" in
    babylonnet )
        wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/tezos-endorser-005-PsBabyM1 \
             -P "$base_dir/"
        wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/tezos-baker-005-PsBabyM1 \
             -P "$base_dir/"
        cat > "$node_dir/config.json" <<- EOM
{
  "p2p": {},
  "network": {
    "genesis": {
      "timestamp": "2019-09-27T07:43:32Z",
      "block": "BLockGenesisGenesisGenesisGenesisGenesisd1f7bcGMoXy",
      "protocol": "PtBMwNZT94N7gXKw4i273CKcSaBrrBnqnt3RATExNKr9KNX2USV"
    },
    "genesis_parameters": {
      "values": {
        "genesis_pubkey": "$genesis_key"
      }
    },
    "chain_name": "TEZOS_ALPHANET_BABYLON_2019-09-27T07:43:32Z",
    "old_chain_name": "TEZOS_ALPHANET_BABYLON_2019-09-27T07:43:32Z",
    "incompatible_chain_name": "INCOMPATIBLE",
    "sandboxed_chain_name": "SANDBOXED_TEZOS",
    "default_bootstrap_peers": []
  }
}
EOM
        ;;
    carthagenet )
        wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/tezos-endorser-006-PsCARTHA \
             -P "$base_dir/"
        wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/tezos-baker-006-PsCARTHA \
             -P "$base_dir/"
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
        ;;
    *)
        echo "$base_chain not supported. Only 'babylonnet' and 'carthagenet' are supported."
        exit 1
esac
chmod +x "$base_dir"/tezos-*
