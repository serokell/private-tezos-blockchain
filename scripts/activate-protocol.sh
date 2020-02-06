#! /usr/bin/env bash
set -euo pipefail

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER="Y"

activate_protocol() {
    "$tezos_client" -d "$client_dir" --block genesis activate protocol \
      "$protocol" with fitness "$fitness" and key genesis and parameters "$parameters"
}
bake_block() {
    "$tezos_client" -d "$client_dir" bake for baker --minimal-timestamp
}

usage() {
    echo "This script will activate a new protocol and bake the first block."
    echo "OPTIONS:"
    echo "  --base-dir <filepath>. Base directory for storing tezos-client"
    echo "    data."
    echo "  --tezos-client <filepath>. Path for patched tezos-client executable"
    echo "  --parameters <filepath>. Path to JSON file with protocol parameters."
    echo "  [--fitness <int>]. Protocol activation fitness, default value is $fitness."
    echo "  [--protocol <protocol-name>]. Protocol to activate, default value is"
    echo "  $protocol"

}

protocol="PsBabyM1eUXZseaJdmXFApDSBqj8YBfwELoxZHHW77EMcAbbwAS"
fitness="25"

if [[ $# -eq 0 || $1 == "--help" ]]; then
    usage
    exit 1
fi

while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
        --base-dir | -d )
            base_dir="$2"
            shift 2
            ;;
        --tezos-client)
            tezos_client="$2"
            shift 2
            ;;
        --parameters)
            parameters="$2"
            shift 2
            ;;
        --fitness)
            fitness="$2"
            shift 2
            ;;
        --procotol)
            protocol="$2"
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

if [[ -z ${tezos_client-} ]]; then
    echo "\"--tezos-client\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${base_dir-} ]]; then
    echo "\"--base-dir\" wasn't provided."
    exit_flag="true"
fi

if [[ -z ${parameters-} ]]; then
    echo "\"--parameters\" wasn't provided."
    exit_flag="true"
fi

[[ $exit_flag == "true" ]] && exit 1

mkdir -p "$base_dir"
client_dir="$base_dir/client"
mkdir -p "$client_dir"
activate_protocol
bake_block
