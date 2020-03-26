<!--
   - SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
   -
   - SPDX-License-Identifier: MPL-2.0
   -->

# Running private blockchain

This doc will describe how to run your own private Tezos blockchain.

## General overview

In order to run a private blockchain, you should do the following:
* Generate a new genesis key, and build patched binaries
(using the `build-patched-binaries.sh` script).
* Run a number of nodes and bakers - at least two, but the more the better
(using the `start-baker.sh` script).
* Customize the chain parameters and activate the procotol
(using the `activate-protocol.sh` script).
* Experiment with the chain.

There are two ways to use these scripts:
1) Run them as is on your machine.
2) Run them inside a docker container.

More detailed instructions are presented in the following sections.

## Running the scripts inside Docker

### Prerequisites

We assume you have docker installed and running.

The file [`Dockerfile`](./Dockerfile) will be used to build a docker image
with all the required tezos dependencies.
Run the following command:
```sh
docker build -t ubuntu-tezos .
```

In order to use this image you will also need a docker volume. To create one, run the following command:
```sh
docker volume create ubuntu-tezos-volume
```

This docker image has [`./scripts/docker.sh`](./scripts/docker.sh) as an entrypoint.
This script wraps the [`build-patched-binaries.sh`](./scripts/build-patched-binaries.sh)
and [`start-baker.sh`](./scripts/start-baker.sh) scripts providing the required paths
to the tezos-binaries stored inside the docker volume.

### Generating a new genesis public key and building patched binaries

To generate patched binaries and create a new genesis public key, run the following:
```
docker run -v ubuntu-tezos-volume:/base-dir -i \
  -t ubuntu-tezos build-binaries --base-chain carthagenet
```

If you have been provided a genesis public key, instead run:
```
docker run -v ubuntu-tezos-volume:/base-dir -i -t ubuntu-tezos build-binaries \
  --genesis-key <provided key> --base-chain carthagenet
```

### Running a baker
To run a baker inside the docker container enter the following:
```sh
docker run --expose 8733 -p 8732:8732 -p 8733:8733 -v ubuntu-tezos-volume:/base-dir \
  -i -t ubuntu-tezos start-baker --net-addr-port 8733 --base-chain carthagenet
```
The --expose parameter makes a port available outside of Docker, while the -p parameter maps local ports to Docker ports.

Port `8732` is used as an node rpc port and exposed by the docker image by default.


If run sucessfully, this script will output something similar to the following:
```sh
      Hash: tz1SJNRNLwACDSLDLk249vFnZjZyV9MVNKEg
      Public Key: edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz
      Secret Key: unencrypted:edsk3mXNLyaNXdFv6Qjcxmfed3eJ7kSzJwgCjSNh4KTTpwRRLPMSpY
```
### Activating procotol and starting blockchain
The Public Key from the previous step will now need to be pasted into a JSON paramter file.

Two sample JSON files are provided, depending on the version of the network you plan to run:
* ./parameters/parameters_babylonnet.json
* ./parameters/parameters_carthagenet.json

In these files, `bootstrap_accounts` has information about account public keys
that have access to tokens (4M of tez in these example files). Note
that all bakers should have some tokens, thus, we need to add the public key for the baker just created into `bootstrap_accounts`.

Starting with the appropriate sample file for the network version you plan to run,
modify it by adding an entry in the bootstrap_accounts section for the public key provided in the previous step.

e.g. paste an entry like this into the bootstrap_accounts section:
```sh
    [
      "edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz",
      "4000000000000"
    ],
```
The exisiting bootstrap accounts should remain in the file, and will be used later in this example.

Copy the edited parameters file to the docker filesystem:
```sh
docker cp my-parameters.json <container_name>:/parameters.json
```
where my-parameters.json is the file you have just edited. The <container_name> can be retrieved by the command 'docker ps'

The last step is to run the activation script for the running docker container:
```sh
docker exec <container_name> ./scripts/activate-protocol.sh \
  --base-dir /base-dir --tezos-client /base-dir/tezos-client \
  --parameters /parameters.json
```

If you want to browse the file system inside your Docker container, you can run the command:
```sh
docker exec -it <container_name> bash
```
This will run an interactive shell session inside your running node container.

### Using the private chain
Before continuing, you can verify things are working properly by entering into your browser:
```sh
http://localhost:8732/chains/main/blocks/head
```
You should see some valid JSON being returned. If things are not working correctly, you can look at the contents of the files
```sh
base-dir/baker.log
base-dir/node.log
```
for possible error messages.


Once the protocol is activated, you can play with the new chain.
For example, you can transfer some tokens from one account to another using `tezos-client`.

We will use the alias 'alice' to refer to the bootstrap_accounts entry with these values:
```sh
Hash: tz1akcPmG1Kyz2jXpS4RvVJ8uWr7tsiT9i6A
Public Key: edpktezaD1wnUa5pT2pvj1JGHNey18WGhPc9fk9bbppD33KNQ2vH8R
Secret Key: unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG
```
Enter the following command:
```sh
$ tezos-client import secret key alice unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG
```
If the alias is already defined, you will get the following error (which you can ignore as long as the secret key matches the entry in bootstrap_accounts):

```sh
Error:
  The secret_key alias alice already exists.
    The current value is unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG.
    Use --force to update
```
If the secret key does not match, you can re-run the previous command adding --force onto the end

Account `alice` has 4m of tez available.

The secret keys used here are unencrypted, which is unsafe in general but used to for simplicity of the examples.
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

```sh
#TODO: This gives the following error message, even though the transfer seems to succeed:
# Fatal error:
#  transfer simulation failed
```

After this, `bob` will have some tokens:
```sh
$ tezos-client get balance for bob
100.0 ꜩ
```

### Additional notes

Docker cannot acess files outside its container, so you will need to remember to copy any required files (contract code files, etc.) before originating them inside the docker container.

Consider using different `base-dir`s for different private chains, otherwise you
highly likely will encounter baking errors. Also, nodes from different chains shouldn't be able
to communicate with each other.

```sh
#TODO: See if we can update the Docker example to run two bakers. Update the following comment depending on how we manage to do it
```
As well as different `base-dir`, you should use different docker volumes for different
nodes even if they're running on the same chain.

## Running the scripts without Docker
### Prerequisites
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

### Generating new genesis public key and building patched binaries
First step for running the private blockchain is generating a new genesis public key and
building patched Tezos binaries. The [`build-patched-binaries.sh`](./scripts/build-patched-binaries.sh)
shell script will build these patched binaries.

There are two ways to use this script:
* You are the one who initiates the new private blockchain creation (the so-called dictator).
Thus, you'll have to generate a new genesis public key. In order to do that, you can run
the following command:
```sh
./scripts/build-patched-binaries.sh --base-dir dictator --patch-template ./patches/patch_template.patch \
  --base-chain carthagenet
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
./scripts/build-patched-binaries.sh --base-dir user --genesis-key <provided key> --base-chain carthagenet
```
After running this command, the `user` directory will contain patched Tezos binaries.

### Running baker
In order to run baker, you should use the [`start-baker.sh`](./scripts/start-baker.sh)
shell script, for this you will need Tezos binaries from the previous step.

Let's suppose a baker has built binaries using `base-dir` with some provided genesis key.
Also, on this step you need to specify an IP address on which the baker can be accessed on the network.
Here is an example of script usage:
```sh
#TODO: Also, we should probably include a two-baker configuration set that can work for the localhost tutorial. In a one-baker version the '--peer' address is just a dummy address and is not neeeded

./scripts/start-baker.sh --base-dir base-dir \
  --tezos-client base-dir/tezos-client --tezos-node base-dir/tezos-node \
  --tezos-baker base-dir/tezos-baker-005-PsBabyM1 --tezos-endorser base-dir/tezos-endorser-005-PsBabyM1 \
  --rpc-addr localhost:8732 --net-addr localhost:8832 \
  --peer localhost:8833 --base-chain carthagenet

#Note that addresses specified as --peer should be addresses specified as '--net-addr' of another node
```
This script will generate the new node identity in the `baker/node` directory and the new Tezos account
with `baker` alias (all `tezos-client` related files will be accessible in the `baker/client` directory).

This `baker` public key should be provided to the chain dictator (the person who initiated
the private chain creation). This public key can be found in the `baker/client/public_keys` file.
After identity and account generation, this script will run `tezos-node` along
with baker and endorser daemons in the background. Once the new protocol is activated, it will start baking blocks.

To stop the baker, do the following:
```sh
./scripts/start-baker.sh --base-dir base-dir stop
```

To see information about the baker, run:

```
tezos-client -d base_dir/client show address baker
# add -S to see secret key as well
```

We recomend having at least two nodes and bakers in your private chain, but the more the better.

If you want to have single-node chain, you can change `--bootstrap-threshold` parameter to
zero in [`start-baker.sh`](./scripts/start-baker.sh#L28)

### Activating procotol and starting blockchain
After building and running the baker on the dictator machine, the dictator should activate the protocol
and bake the first block by running the [`activate-protocol.sh`](./scripts/activate-protocol.sh) shell script.
After activating the new protocol and baking the first block, the private blockchain will start.

Let's suppose the dictator built binaries and started a baker using the `base-dir` directory.
E.g. the following commands were executed:
```sh
./scripts/build-patched-binaries.sh --base-dir base-dir --patch-template ./patches/patch_template.patch
./scripts/start-baker.sh --base-dir base-dir \
  --tezos-client base-dir/tezos-client --tezos-node base-dir/tezos-node \
  --tezos-baker base-dir/tezos-baker-005-PsBabyM1 --tezos-endorser base-dir/tezos-endorser-005-PsBabyM1
  --net-addr 10.147.19.192:8732 --base-chain carthagenet
```
```sh
#TODO: The following section can be combined with the similar section in the Docker example, as long as it doesnt make the flow too confusing
If run sucessfully, this script will output something similar to the following:

      Hash: tz1SJNRNLwACDSLDLk249vFnZjZyV9MVNKEg
      Public Key: edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz
      Secret Key: unencrypted:edsk3mXNLyaNXdFv6Qjcxmfed3eJ7kSzJwgCjSNh4KTTpwRRLPMSpY

The Public Key value will need to be pasted into a JSON paramter file that we will provide when launching the blockchain

Two sample files are provided, depending on the version of the network you plan to run:
* [babylonnet](./parameters/parameters_babylonnet.json)
* [carthagenet](./parameters/parameters_carthagenet.json)

In these files, `bootstrap_accounts` has information about account public keys
that have access to tokens (4M of tez in these example files). Note
that all bakers should have some tokens, thus, we need to add the public key for the baker just created into `bootstrap_accounts`.

Starting with the appropriate sample file for the network version you plan to run,
modify it by adding an entry in the bootstrap_accounts section for the public key provided in the previous step.

e.g. paste an entry like this into the bootstrap_accounts section:

    [
      "edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz",
      "4000000000000"
    ],

The exisiting bootstrap accounts should remain in the file, and will be used later in this example.
In general recommend having some more bootstrap accounts that are not bakers, because
bakers run out of tokens before they begin to get rewarded for baking. In such situation
the chain can stop.

Now the blockchain is ready to be launched. In order to launch it, the dictator should run the following:
```sh
./scripts/activate-protocol.sh --base-dir base-dir --tezos-client \
  base-dir/tezos-client --parameters my-parameters.json --base-chain carthagenet
```
where my-parameters.json is the file you have just edited.

### Trying it out
See [these steps](#using-the-private-chain) in the Docker section.  They should work both for docker and non-docker installations.



****************************************************************************************************

## Creating a peer-to-peer network

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
