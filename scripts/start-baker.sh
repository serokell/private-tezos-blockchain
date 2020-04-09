#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER="Y"

gen_node_identity() {
    echo "Set up new node:"
    "$tezos_node" identity generate --data-dir "$node_dir"
}

start_node() {
    node_args=("--data-dir" "$node_dir" "--rpc-addr" "$rpc_addr" "--net-addr" "$net_addr" "--no-bootstrap-peers" "--bootstrap-threshold" "1")
    for peer in "${peers[@]:-}"; do
        node_args+=("--peer" "$peer")
    done
    if [[ $background_flag == "false" ]]; then
        "$tezos_node" run "${node_args[@]}"
    else
        ("$tezos_node" run "${node_args[@]}" &>"$base_dir/node.log") &
        echo "$!" >| "$base_dir/node_pid.txt"
    fi
}

gen_baker_account() {
    if [[ $encrypted_flag == "true" ]]; then
        "$tezos_client" -d "$client_dir" gen keys baker --encrypted
    else
        "$tezos_client" -d "$client_dir" gen keys baker
    fi
    echo "Baker info:"
    "$tezos_client" -d "$client_dir" show address baker -S
    echo
}

start_baker() {
    (sleep 5s && "$tezos_baker" -A "$node_ip" -P "$node_port" -d "$client_dir" run with local node "$node_dir" baker &>"$base_dir/baker.log") &
}

start_endorser() {
    (sleep 5s && "$tezos_endorser" -A "$node_ip" -P "$node_port" -d "$client_dir" run baker &>"$base_dir/endorser.log") &
}

usage() {
    echo "This script will run tezos-node along with baker and endorser daemons in the background."
    echo "In order to stop node and daemons run \"./start-baker.sh --base-dir <filepath> stop\"."
    echo "OPTIONS:"
    echo "  --base-dir <filepath>. Base directory for storing tezos-node and"
    echo "    tezos-client data, also for storing node, baker and endorser logs."
    echo "  --tezos-client <filepath>. Path for patched tezos-client executable"
    echo "  --tezos-node <filepath>. Path for patched tezos-node executable"
    echo "  --tezos-baker <filepath>. Path for patched tezos-baker executable"
    echo "  --tezos-endorser <filepath>. Path for patched tezos-endorser executable"
    echo "  [--rpc-addr <rpc-addr>]. Define RPC address of the baker node, default is localhost:8732"
    echo "  --net-addr <net-addr>. Define net address of the baker node"
    echo "  [--peer <net-addr>]. Node peer address. Possible to provide"
    echo "    zero or more peers. Note, that you have to provide at least one peer"
    echo "    for the baker (e.g. use dictator node), otherwise, bakers won't be able"
    echo "    to communicate."
    echo "  [--encrypted]. Define whether generated baker secret key will be encrypted."
    echo "  [--no-background-node]. Run node in the foreground instead of background."
}

rpc_addr="localhost:8732"

if [[ $# -eq 0 || $1 == "--help" ]]; then
    usage
    exit 1
fi

stop_flag="false"
encrypted_flag="false"
background_flag="true"
peers=()

while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --base-dir | -d )
            base_dir="$2"
            shift 2
            ;;
        --peer | -p)
            peers+=("$2")
            shift 2
            ;;
        --tezos-client)
            tezos_client="$2"
            shift 2
            ;;
        --tezos-node)
            tezos_node="$2"
            shift 2
            ;;
        --tezos-baker)
            tezos_baker="$2"
            shift 2
            ;;
        --tezos-endorser)
            tezos_endorser="$2"
            shift 2
            ;;
        --rpc-addr)
            rpc_addr="$2"
            shift 2
            ;;
        --net-addr)
            net_addr="$2"
            shift 2
            ;;
        --encrypted)
            encrypted_flag="true"
            shift
            ;;
        --no-background-node )
            background_flag="false"
            shift
            ;;
        stop)
            stop_flag="true"
            shift
            ;;
        *)
            echo "Unexpected option \"$1\"."
            usage
            exit 1
            ;;
    esac
done

if [[ $stop_flag == "true" ]]; then
    kill -15 "$(<"$base_dir"/node_pid.txt)"
    exit 0
fi

exit_flag="false"

if [[ -z ${base_dir:-} ]]; then
    echo "\"--base-dir\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${tezos_client:-} ]]; then
    echo "\"--tezos-client\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${tezos_node:-} ]]; then
    echo "\"--tezos-node\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${tezos_baker:-} ]]; then
    echo "\"--tezos-baker\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${tezos_endorser:-} ]]; then
    echo "\"--tezos-endorser\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${net_addr:-} ]]; then
    echo "\"--net-addr\" wasn't provided."
    exit_flag="true"
fi

[[ $exit_flag == "true" ]] && exit 1

mkdir -p "$base_dir"
node_dir="$base_dir/node"
client_dir="$base_dir/client"
mkdir -p "$node_dir"
mkdir -p "$client_dir"

node_ip="$(echo "$rpc_addr" | cut -f1 -d":")"
node_port="$(echo "$rpc_addr" | cut -f2 -d":")"

"$tezos_client" -d "$client_dir" show address baker || gen_baker_account
[[ -f $node_dir/identity.json ]] || gen_node_identity
start_baker
start_endorser
start_node
