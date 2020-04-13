#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

script_args=()

usage () {
    echo "This script is used to wrap binaries fetching and baker starting scripts"
    echo "inside docker container."
    echo "COMMANDS:"
    echo "  fetch-binaries [--base-chain <babylonnet | carthagenet>]"
    echo "                 [--genesis-key <public-key>]"
    echo "                 [--encrypted]"
    echo "    Call 'fetch-binaries.sh' script inside docker container."
    echo "    Produced binaries will be stored in '/base-dir' directory inside"
    echo "    docker container."
    echo "  start-baker"
    echo "      [--net-address <address>]"
    echo "       --net-addr-port <port>"
    echo "      [--rpc-address <address>]"
    echo "      [--rpc-addr-port <port>]"
    echo "      [--peer <net-addr>]"
    echo "    Call 'start-baker.sh' script inside docker container."
    echo "    Will use binaries from '/base-dir' directory and 'localhost' as '--net-addr'"
}

if [[ $# -eq 0 || $1 == "--help" ]]; then
    usage
    exit 1
fi

case "$1" in
    fetch-binaries )
        script="fetch"
        ;;
    start-baker )
        script="start"
        ;;
    * )
        "Unexpected command \"$1\""
        exit 1
        ;;
esac
shift

container_ip="$(hostname -i |  tr -d '[:space:]')"
echo "Container IP: $container_ip"
net_address=$container_ip
rpc_address=$container_ip
rpc_addr_port=8732

while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --net-address )
            if [[ $script != "start" ]]; then
                echo "Unexpected option '--net-address' for $script command."
                exit 1
            fi
            net_address="$2"
            shift 2
            ;;
        --net-addr-port )
            if [[ $script != "start" ]]; then
                echo "Unexpected option '--net-addr-port' for $script command."
                exit 1
            fi
            net_addr_port="$2"
            shift 2
            ;;
        --rpc-address )
            if [[ $script != "start" ]]; then
                echo "Unexpected option '--rpc-address' for $script command."
                exit 1
            fi
            rpc_address="$2"
            shift 2
            ;;
        --rpc-addr-port )
            if [[ $script != "start" ]]; then
                echo "Unexpected option '--rpc-addr-port' for $script command."
                exit 1
            fi
            rpc_addr_port="$2"
            shift 2
            ;;
        *)
            script_args+=("$1")
            shift
            ;;
    esac
done

if [[ -z ${net_addr_port:-} ]]; then
    echo "\"--net-addr-port\" wasn't provided."
    exit_flag="true"
fi

case "$script" in
    fetch )
        "./scripts/fetch-binaries.sh" "--base-dir" "/base-dir" \
          "${script_args[@]}"
        ;;
    start )
        "./scripts/start-baker.sh" "--base-dir" "/base-dir" "--tezos-client" "/base-dir/tezos-client" \
          "--tezos-node" "/base-dir/tezos-node" "--tezos-baker" "/base-dir/tezos-baker-"* \
          "--tezos-endorser" "/base-dir/tezos-endorser-"* \
          "--net-addr" "$net_address:$net_addr_port" \
          "--rpc-addr" "$rpc_address:$rpc_addr_port" \
          "--no-background-node" "${script_args[@]}"
        ;;
    *)
        echo "Unpexpected command \"$script\"."
        usage
        exit 1
        ;;
esac
