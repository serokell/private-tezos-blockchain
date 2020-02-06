<!--
   - SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
   -
   - SPDX-License-Identifier: MPL-2.0
   -->

# Running private blockchain

This doc will describe how to run your own private Tezos blockchain.

## General overview

In order to run a private blockchain, you should do the following:
* Generate new genesis key, and build patched binaries
(using `build-patched-binaries.sh` script).
* Run a bunch of nodes and bakers, at least two, but the more the better
(using `start-baker.sh` script).
* Customize chain parameters to your taste and activate the procotol
(using `activate-protocol.sh` script).
* Play with your chain.

More detailed instructions are presented further.

## Prerequisites

Since running a private blockchain requires compiling patched Tezos binaries from
scratch, you will have to install the following dependencies:
```
rsync git m4 build-essential patch unzip bubblewrap wget pkg-config
libgmp-dev libev-dev libhidapi-dev which opam
```
These dependencies are also described [here](https://tezos.gitlab.io/introduction/howtoget.html#build-from-sources).

In order to install them using a Debian or RedHat-based distro, run one of the following
commands:
```sh
# Debian and apt
sudo apt update && sudo apt install rsync git m4 build-essential patch unzip \
     bubblewrap wget pkg-config libgmp-dev libev-dev libhidapi-dev which
# RedHat and yum
sudo yum update && sudo yum install rsync git m4 patch unzip make \
     bubblewrap wget gmp-devel libev-devel perl-Pod-Html pkgconfig hidapi-devel which
```
In order to install `opam`, run the following commands:
```sh
wget https://github.com/ocaml/opam/releases/download/2.0.3/opam-2.0.3-x86_64-linux
sudo cp opam-2.0.3-x86_64-linux /usr/local/bin/opam
sudo chmod a+x /usr/local/bin/opam
```

## Generating new genesis public key and building patched binaries

First step for running the private blockchain is generating a new genesis public key and
building patched Tezos binaries. [build-patched-binaries.sh](./scripts/build-patched-binaries.sh)
shell script will build these patched binaries.

Note that you may have to adjust this script for your needs, e.g. `babylonnet` branch can be changed
to `carthagenet`. Another case is that genesis public key can be moved from
`src/proto_genesis/lib_protocol/data.ml` to another file.

There are two ways to use this script:
* You are the one who initiates the new private blockchain creation (the so-called dictator).
Thus, you'll have to generate a new genesis public key. In order to do that, you can run
the following command:
```sh
./build-patched-binaries.sh --base-dir dictator
```
After running this command, the new genesis public-key will be stored in a `dictator/genesis_key.txt` file,
so that you can share this key with other users of your private blockchain.
Apart from file with the new genesis public key, the `dictator` directory will also contain
patched Tezos binaries required for running the private blockchain.
In addition to this, the `dictator` directory will have a `client` folder, which will contain `tezos-client`
related files, e.g. it will contain the public key hash, public and secret keys for the `genesis` account,
in `dictator/client/public_key_hashs`, `dictator/client/public_keys` and `dictator/client/secret_keys`.
files respectively. This hash and keys will be used later in protocol activation.
To get information about the `genesis` account, run:
```sh
./dictator/tezos-client -d dictator/client show address genesis
```
* Someone provided you a genesis public key. In this case, you should run the following command:
```sh
./build-patched-binaries.sh --base-dir user --genesis-key <provided key>
```
After running this command, the `user` directory will contain patched Tezos binaries.

## Running baker

In order to run baker, you should use the [start-baker.sh](./scripts/start-baker.sh)
shell script, for this you will need Tezos binaries from the previous step.
Let's suppose baker built binaries using `baker` as a `base-dir` with some provided genesis key.
Also, on this step you need to specify an IP address on which baker can be accessed on the
network.
Here is an example of script usage:
```sh
./scripts/start-baker.sh --base-dir baker \
  --tezos-client baker/tezos-client --tezos-node baker/tezos-node \
  --tezos-baker baker/tezos-baker-005-PsBabyM1 --tezos-endorser baker/tezos-endorser-005-PsBabyM1 \
  --net-addr 10.147.19.192:8732
  --peer 10.147.19.49:8732
```
Note that you should provide at least one peer to make the node communicate with the chain (e.g. you
can provide address of the dictator node).
This script will generate the new node identity in the `baker/node` directory and the new Tezos account
with `baker` alias (all `tezos-client` related files will be accessible in the `baker/client` directory),
this `baker` public key should be provided to the chain dictator (person, who initiated
the private chain creation). This public key can be found in the `baker/client/public_keys` file.
After identity and account generation, this script will run `tezos-node` along
with baker and endorser daemons in the background. Now, once the new protocol is activated, it will start baking blocks.

To stop the baker, do the following:
```sh
./scripts/start-baker.sh --base-dir baker stop
```

We recomend having at least two nodes and bakers in your private chain, but the more the better.

## Activating procotol and starting blockchain

After building and running the baker on the dictator machine, the dictator should activate protocol
and bake the first block. In order to do that, one should use
[activate-protocol.sh](./scripts/activate-protocol.sh) shell script.
It will activate the new protocol and bake the first block, after that the private blockchain will
actually start.

Let's suppose dictator built binaries and started baker using `dictator` as a `base-dir`.
E.g. the following commands were executed:
```sh
./scripts/build-patched-binaries.sh --base-dir dictator
./scripts/start-baker.sh --base-dir dictator \
  --tezos-client dictator/tezos-client --tezos-node dictator/tezos-node \
  --tezos-baker dictator/tezos-baker-005-PsBabyM1 --tezos-endorser dictator/tezos-endorser-005-PsBabyM1
  --net-addr 10.147.19.192:8732
```
Now the blockchain is ready to be launched. In order to launch it, the dictator should run the following:
```sh
./scripts/activate-protocol.sh --base-dir dictator --tezos-client \
  dictator/tezos-client --parameters parameters.json
```
`parameters.json` describes different chain parameters, here is a sample parameter file:
```
{
  "bootstrap_accounts": [
    [
      "edpkvRk8HnYe9tAgTEAYEhSo4N7qcrjoAFnj4ZiRb7DxFDijdrXxbK",
      "4000000000000"
    ],
    [
      "edpkvUS1z9QGXr6f89dNF5WyeRCFuK6PYWYrMHcpU9kQ2TevD66fDG",
      "4000000000000"
    ],
    [
      "edpktezaD1wnUa5pT2pvj1JGHNey18WGhPc9fk9bbppD33KNQ2vH8R",
      "4000000000000"
    ]
  ],
  "preserved_cycles": 2,
  "blocks_per_cycle": 8,
  "blocks_per_commitment": 4,
  "blocks_per_roll_snapshot": 4,
  "blocks_per_voting_period": 64,
  "time_between_blocks": [
    "10",
    "20"
  ],
  "endorsers_per_block": 32,
  "hard_gas_limit_per_operation": "800000",
  "hard_gas_limit_per_block": "8000000",
  "proof_of_work_threshold": "-1",
  "tokens_per_roll": "8000000000",
  "michelson_maximum_type_size": 1000,
  "seed_nonce_revelation_tip": "125000",
  "origination_size": 257,
  "block_security_deposit": "512000000",
  "endorsement_security_deposit": "64000000",
  "block_reward": "16000000",
  "endorsement_reward": "2000000",
  "cost_per_byte": "1000",
  "hard_storage_limit_per_operation": "60000",
  "test_chain_duration": "1966080",
  "quorum_min": 2000,
  "quorum_max": 7000,
  "min_proposal_quorum": 500,
  "initial_endorsers": 1,
  "delay_per_missing_endorsement": "1"
}
```
In this configuration, `bootstrap_accounts` has information about account public keys
which will have some tokens (4M of tez in this example) after the chain start. Note
that all bakers should have some tokens, thus, they should be listed in `bootstrap_accounts`.

## Using private chain

Once the protocol is activated, you can play with the new chain.
For example, you can transfer some tokens from one account to another using `tezos-client`.
You will need either a local or a remote node for this.

Account `alice` has 4m of tez as a bootstrap account, `alice`'s account info
(its public key is listed in `bootstrap_accounts`):
```
Hash: tz1akcPmG1Kyz2jXpS4RvVJ8uWr7tsiT9i6A
Public Key: edpktezaD1wnUa5pT2pvj1JGHNey18WGhPc9fk9bbppD33KNQ2vH8R
Secret Key: unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG
```
Note that `alice` should be a known alias for your `tezos-client`. In order to add it,
do the following
```sh
$ tezos-client import secret key alice unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG
```
However, unencrypted secret key usage is unsafe and used to provide more simplicity in this manual.
Consider not using them if you care about privacy (even in a private blockchain without real money).
In order to encrypt bakers and genesis secret keys, you can provide an `--encrypted` flag
to `build-patched-binaries.sh` and `start-baker.sh` scripts.

Let's generate a new account named `bob`:
```sh
$ tezos-client gen keys bob
$ tezos-client show address bob
Hash: tz1iW2e1i355D57GSuBHw928mJkuCwcZZWmk
Public Key: edpku66KahHGQsthyuHmsYm829xnH6jWXiapkyaNf1HspXx5VKKPSu
```

And transfer some tokens:
```sh
$ tezos-client transfer 100 from alice to bob --burn-cap 0.257
```

After this, `bob` will have some tokens:
```sh
$ tezos-client get balance for bob
100.0 ꜩ
```

## Additional notes

Consider using different `base-dir`s for different private chains, otherwise you
highly likely will encounter baking errors. Also, nodes from different chains shouldn't be able
to communicate with each other.

### Creating peer-to-peer network

It is convenient to use a dedicated peer-to-peer network in order to run private
blockchain.

One way to do that is to use the [ZeroTier](https://www.zerotier.com/) service.

In order to create and use peer-to-peer network, you should do the following steps:

1. Create a new ZeroTier account.

2. Download the ZeroTier VPN service for your OS (Mac, Windows and Linux versions
are available).

3. Download and install the VPN service. Mac, Windows and Linux versions are available.
Once installed, your machine will be associated with a Node ID (10-digit address).


4. Go to the Network section of ZeroTier Central and create a new network.
New network will be assotiated with Network ID.
In order to join the Zerotier network run `sudo zerotier-cli join <network-id>`
Then, ask participants to join. Use the Node IDs that were provided for your
machine to add your machine to the network.

5. Ask other participants to also create a ZeroTier account and join the network you just created.

Once you have joined the network, you will be assigned an IP-address, that you can share with other
participants.

To find this IP-address, simply run `ifconfig`, the name of ZeroTier network interface
starts with `zt` prefix.
