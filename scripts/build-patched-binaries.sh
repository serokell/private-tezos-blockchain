#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER="Y"

gen_genesis_key() {
    # download tezos-client if not presented to generate new public key
    if [[ ! -f $base_dir/tezos-client ]]; then
        wget https://github.com/serokell/tezos-packaging/releases/download/202001141534/tezos-client-babylonnet-b8731913 \
        -O "$base_dir"/tezos-client
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
    echo "  [--encrypted]. Define whether the generated genesis secret key will be encrypted"
}

if [[ $# -eq 0 || $1 == "--help" ]]; then
    usage
    exit 1
fi

encrypted_flag=false
genesis_key=""
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
        *)
            echo "Unexpected option \"$1\"."
            usage
            exit 1
            ;;

    esac
done

if [[ -z ${base_dir:-} ]]; then
    echo "\"--base-dir\" wasn't provided."
    exit 1
fi

mkdir -p "$base_dir"
client_dir="$base_dir/client"
mkdir -p "$client_dir"

[[ -z $genesis_key ]] && gen_genesis_key

cd "$base_dir"
# You can change base branch for your binaries here
git clone --single-branch --branch babylonnet https://gitlab.com/tezos/tezos.git --depth 1
cd tezos
# Update this once genesis public key is moved to another file
sed -i s/edpkugeDwmwuwyyD3Q5enapgEYDxZLtEUFFSrvVwXASQMVEqsvTqWu/"$genesis_key"/ \
    src/proto_genesis/lib_protocol/data.ml

opam init --bare
make build-deps && eval "$(opam env)" && make
chmod +x tezos-*
cp tezos-client ../
cp tezos-node ../
cp tezos-endorser-* ../
cp tezos-baker-* ../
cd ..
rm -rf tezos
