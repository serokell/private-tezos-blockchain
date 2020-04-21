#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

base_dir=/base-dir
mkdir -p "$base_dir"
mkdir -p "$base_dir/client"
mkdir -p "$base_dir/node"

prefix=https://github.com/serokell/tezos-packaging/releases/download/202004061400

wget $prefix/tezos-client -P "$base_dir/"
wget $prefix/tezos-node -P "$base_dir/"
wget $prefix/tezos-endorser-006-PsCARTHA -P "$base_dir/"
wget $prefix/tezos-baker-006-PsCARTHA -P "$base_dir/"

chmod +x "$base_dir"/tezos-*
