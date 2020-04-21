#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

fetch-binaries() {
    echo "...fetch-binaries done."
    /scripts/fetch-binaries.sh
    echo "...fetch-binaries done.\n"
}

start-baker() {
  echo "start-baker..."
  echo "peer: $peer"
  /scripts/start-baker.sh \
    --base-dir /base-dir \
    --tezos-client /base-dir/tezos-client \
    --tezos-node /base-dir/tezos-node \
    --tezos-baker "/base-dir/tezos-baker" \
    --tezos-endorser "/base-dir/tezos-endorser" \
    --net-addr :8732 \
    --rpc-addr :8733 \
    --no-background-node \
    --peer $peer
    #   --encrypted
    echo "...start-baker done.\n"
}

peer=""
while true; do
    if [[ $# -eq 0 ]]; then
        break
    fi
    case "$1" in
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

if [[ -z ${peer:-} ]]; then
    echo "\"--peer\" wasn't provided."
    exit_flag="true"
fi

[[ $exit_flag == "true" ]] && exit 1

fetch-binaries
start-baker
