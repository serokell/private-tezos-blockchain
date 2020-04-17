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
