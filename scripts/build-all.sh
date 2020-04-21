#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

set -euo pipefail

rm -rf base-dir
echo "fetching tezos-client for build..."
scripts/fetch-local-client.sh
echo "...fetch local client done.\n"

echo "TBD: read network config file..."
peer="ec2-3-12-165-223.us-east-2.compute.amazonaws.com:8733"

echo "pre-generate keys, etc...."
source scripts/pre-gen.sh
echo $genesis_key
echo "...pre-generation done.\n"

echo "write-config..."
scripts/write-config.sh --genesis-key $genesis_key --peer $peer
echo "write-config...Done.\n"

echo "running docker build..."
docker build -t ubuntu-tezos .
echo "...docker build done.\n"

echo "creating docker volume..."
docker volume create ubuntu-tezos-volume
echo "....docker volume done.\n"
