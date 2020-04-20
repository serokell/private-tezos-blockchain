source scripts/pre-gen.sh
echo $genesis_key

scripts/write-config.sh --genesis-key $genesis_key
