#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

base_dir=base-dir

rm -rf $base_dir
mkdir -p "$base_dir"
mkdir -p "$base_dir/client"
mkdir -p "$base_dir/node"

prefix=https://github.com/serokell/tezos-packaging/releases/download/202004061400
wget $prefix/tezos-client -P "$base_dir/"
chmod +x "$base_dir"/tezos-*

source scripts/generate-keys.sh
echo $genesis_key

scripts/write-config.sh --genesis-key $genesis_key

#generated baker keys with tz TBD...
scripts/write-params.sh

docker build -t ubuntu-tezos .

docker volume create ubuntu-tezos-volume
