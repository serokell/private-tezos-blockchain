<!--
   - SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
   -
   - SPDX-License-Identifier: MPL-2.0
   -->

# Running a private blockchain

This doc will describe how to run your own private Tezos blockchain.

## General overview

In order to run a private blockchain, you should do the following:
* Generate a new genesis key, and fetch binaries
(using the `fetch-binaries.sh` script).
* Run a number of nodes and bakers - at least two, but the more the better
(using the `start-baker.sh` script).
* Customize the chain parameters and activate the procotol
(using the `activate-protocol.sh` script).
* Experiment with the chain.

There are two ways to use these scripts:
1) Run them inside a docker container.
2) Run them directly on your local machine.

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

In order to use this image you will also need two docker volumes. Run the following commands:
```sh
docker volume create ubuntu-tezos-volume
docker volume create ubuntu-tezos-volume-1
```

These docker images have [`./scripts/docker.sh`](./scripts/docker.sh) as their entrypoint.
This script wraps the [`fetch-binaries.sh`](./scripts/fetch-binaries.sh)
and [`start-baker.sh`](./scripts/start-baker.sh) scripts, providing the required paths
to the tezos-binaries stored inside the docker volumes.

### Generating a new genesis public key and fetching binaries

To fetch Tezos binaries and create a new genesis public key, run the following:
```
docker run -v ubuntu-tezos-volume:/base-dir -i \
  -t ubuntu-tezos fetch-binaries --base-chain carthagenet
```

If you have been provided a genesis public key, instead run:
```
docker run -v ubuntu-tezos-volume:/base-dir -i -t ubuntu-tezos fetch-binaries \
  --genesis-key <provided key> --base-chain carthagenet
```

### Running the first baker
This example will walk you through running two bakers, each running in its own Docker container.
To run the first, enter the following:
```sh
docker run --expose 8733 -p 8732:8732 -p 8733:8733 -v ubuntu-tezos-volume:/base-dir \
  -i -t ubuntu-tezos start-baker --net-addr-port 8733
```
The --expose parameter makes a port available outside of Docker, while the -p parameter maps local ports to Docker ports.

Port `8732` is used as an node rpc port and exposed by the docker image by default.

In this command and some that follow, you will see a warning:
```sh
Warning:
  Failed to acquire the protocol version from the node
  Rpc request failed:
     - meth: GET
     - uri: http://localhost:8732/chains/main/blocks/head/protocols
     - error: Unable to connect to the node: "Unix.Unix_error(Unix.ECONNREFUSED, "connect", "")"
```
These warnings can be ignored for now, as all the required components have not yet been started.

This script will print the baker's IP address and public key, both of which will be used in the following steps.
First your should see the IP address:
```sh
Container IP: 172.17.0.2
```
This IP address will used as a peer for the second node we create.

You will also see some output containing the public key:
```sh
      Hash: tz1SJNRNLwACDSLDLk249vFnZjZyV9MVNKEg
      Public Key: edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz
      Secret Key: unencrypted:edsk3mXNLyaNXdFv6Qjcxmfed3eJ7kSzJwgCjSNh4KTTpwRRLPMSpY
```

At this point, you should also see 'Too few connections (0)' being printed repeatedly on the terminal.
Leave this terminal running and open another.

In this second terminal window, enter:

```sh
docker run -v ubuntu-tezos-volume-1:/base-dir -i \
  -t ubuntu-tezos fetch-binaries --base-chain carthagenet
```

And now run the 2nd baker:
```sh
docker run --expose 8734 -p 8734:8734 -v ubuntu-tezos-volume-1:/base-dir \
  -i -t ubuntu-tezos start-baker --net-addr-port 8734 --peer 172.17.0.2:8733
```

If the nodes are able to sucessfully see each other you will see the following lines output in both the first and second shell windows:
```sh
p2p.maintenance: Too few connections (1)
```

This means that each node now has one peer.

Assuming the calls to start-baker.sh were successful, the output from each should have something like:
```sh
      Hash: tz1SJNRNLwACDSLDLk249vFnZjZyV9MVNKEg
      Public Key: edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz
      Secret Key: unencrypted:edsk3mXNLyaNXdFv6Qjcxmfed3eJ7kSzJwgCjSNh4KTTpwRRLPMSpY
```
The public key from this output will be used in the next step

### Activating the procotol and starting the blockchain
Leave the second shell running as well, and open a third session. In the new shell, first get the names of the two containers that are now running via the command:
```sh
docker ps
```
#### Modifying the parameter files
We also need to gather the public keys created from the two bakers started in the previous steps.
These public keys will need to be pasted into a JSON parameter file.

Two sample JSON files are provided, depending on the version of the network you plan to run:
* ./parameters/parameters_babylonnet.json
* ./parameters/parameters_carthagenet.json

In these files, `bootstrap_accounts` has information about account public keys
that have access to tokens (4M of tez in these example files). Note
that all bakers should have some tokens, thus, we need to add the public key for the baker just created into `bootstrap_accounts`.

Starting with the appropriate sample file for the network version you plan to run,
modify it by adding an entry in the bootstrap_accounts section for each of the two public key provided in the previous step.

e.g. paste entries like this into the bootstrap_accounts section:
```sh
    [
      "edpkvRTXYRCxCbWs4GF1shMxCab9nF3iNimPqqb2esiP5WyjAhT1dz",
      "4000000000000"
    ],
    [
      "edpkum3W1vGfsF19uNNnjdThGvbTBXbBcKyCmEAuV5TPfensRxYyqA",
      "4000000000000"
    ],
```
The exisiting bootstrap accounts should remain in the file, and will be used later in this example.

#### Copying the edited parameter files to Docker
Copy the edited parameters file to the two docker filesystems:
```sh
docker cp my-parameters.json <container_name>:/parameters.json
docker cp my-parameters.json <container_name_1>:/parameters.json
```
where my-parameters.json is the file you have just edited. <container_name> and <container_name_1> can be retrieved by the command 'docker ps'

#### Starting the blockchain
The last step is to run the activation script for the running docker containers.
For this step, choose the container name corresponding to the first container we created (select the one shown to have been started earliest)
```sh
docker exec <container_name> ./scripts/activate-protocol.sh \
  -A <container_ip> -P 8732
  --base-dir /base-dir --tezos-client /base-dir/tezos-client \
  --parameters /parameters.json
```
where <container_ip> is the IP address displayed when we ran the first baker

If you want to browse the file system inside your Docker container, you can run the command:
```sh
docker exec -it <container_name> bash
```
This will run an interactive shell session inside your running node container.

### Using the private chain
Before continuing, you can verify things are working properly by entering into your browser:
```sh
http://<conainer_ip>:8732/chains/main/blocks/head
```
You should see some valid JSON being returned. If things are not working correctly, you can look at the contents of the files
```sh
base-dir/baker.log
base-dir/node.log
```
inside the Docker file system for possible error messages.

Once the protocol is activated, you can play with the new chain.
For example, you can transfer some tokens from one account to another using `tezos-client`.

You can either use the tezos-client which is located inside this example's Docker container or obtain one from https://github.com/serokell/tezos-packaging The following instructions assume you are using the tezos-client inside the docker container.

We will use the alias 'alice' to refer to the bootstrap_accounts entry with these values:
```sh
Hash: tz1akcPmG1Kyz2jXpS4RvVJ8uWr7tsiT9i6A
Public Key: edpktezaD1wnUa5pT2pvj1JGHNey18WGhPc9fk9bbppD33KNQ2vH8R
Secret Key: unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG
```
Enter the following command:
```sh
$ docker exec <container_name>/base-dir/tezos-client \
  --addr <container_ip> --port 8732 \
  import secret key alice unencrypted:edsk2vKVH2BNwKrxJrvbRvuHnu4FW17Jrs2Uy2TzR2fxipikTJJ1aG
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
to `fetch-binaries.sh` and `start-baker.sh` scripts.

Let's generate a new account named `bob`:
```sh
$ docker exec <container_name> /base-dir/tezos-client \
  --addr <container_ip> --port 8732 \
  gen keys bob

$ docker exec <container_name> /base-dir/tezos-client \
  --addr <container_ip> --port 8732 \
show address bob

Hash: tz1iW2e1i355D57GSuBHw928mJkuCwcZZWmk
Public Key: edpku66KahHGQsthyuHmsYm829xnH6jWXiapkyaNf1HspXx5VKKPSu
```
```sh
$ docker exec <container_name> /base-dir/tezos-client \
  --addr <container_ip> --port 8732 \
  --wait none transfer 100 from alice to bob --burn-cap 0.257
```

After this, `bob` will have some tokens:
```sh
$ docker exec <container_name> /base-dir/tezos-client \
  --addr <container_ip> --port 8732 \
  get balance for bob

100.0 ꜩ
```
Note: You might have to wait a minute and rerun the previous command if you don't see the updated balance.

### Additional notes

Docker cannot acess files outside its container, so you will need to remember to copy any required files (contract code files, etc.) before originating them inside the docker container.

## Running the scripts without Docker
### Prerequisites

We will use statically built Tezos binaries from [tezos-packaging](https://github.com/serokell/tezos-packaging). You will need a Linux distribution to be able to run these binaries, and you will also need `wget`.

### Generating a new genesis public key and fetching binaries
The first step for running the private blockchain is generating a new genesis public key and
fetching the Tezos binaries via the [`fetch-binaries.sh`](./scripts/fetch-binaries.sh)
shell script.

There are two ways to use this script:
* You are the one who initiates the new private blockchain creation (the so-called dictator).
Thus, you'll have to generate a new genesis public key. In order to do that, you can run
the following command:
```sh
./scripts/fetch-binaries.sh --base-dir base-dir --base-chain carthagenet
```
After running this command, the new genesis public-key will be stored in a `base-dir/genesis_key.txt` file,
so that you can share this key with other users of your private blockchain.
Apart from file with the new genesis public key, the `base-dir` directory will also contain
the Tezos binaries required for running the private blockchain.
In addition to this, the `base-dir` directory will have a `client` folder, which will contain `tezos-client`
related files, e.g. it will contain the public key hash, public and secret keys for the `genesis` account,
in `base-dir/client/public_key_hashs`, `base-dir/client/public_keys` and `base-dir/client/secret_keys`.
files respectively. This hash and keys will be used later in protocol activation.

To get information about the `genesis` account, run:
```sh
./base-dir/tezos-client -d base-dir/client show address genesis
```
* Someone provided you a genesis public key. In this case, you should run the following command:
```sh
./scripts/fetch-binaries.sh --base-dir user --genesis-key <provided key> --base-chain carthagenet
```
After running this command, the `user` directory will contain the Tezos binaries.

### Running bakers
In order to run bakers, you should use the [`start-baker.sh`](./scripts/start-baker.sh)
shell script. We will also need the modified Tezos binaries from the previous step.

Assume a baker has built binaries using `base-dir` with some provided genesis key.
Enter these commands to run two bakers:
```sh
./scripts/start-baker.sh --base-dir base-dir \
 --tezos-client base-dir/tezos-client --tezos-node base-dir/tezos-node \
 --tezos-baker base-dir/tezos-baker-006-PsCARTHA --tezos-endorser base-dir/tezos-endorser-006-PsCARTHA \
 --rpc-addr localhost:8732 --net-addr localhost:8832 \
 --peer localhost:8833 --base-chain carthagenet

./scripts/start-baker.sh --base-dir base-dir-b \
 --tezos-client base-dir/tezos-client --tezos-node base-dir/tezos-node \
 --tezos-baker base-dir/tezos-baker-006-PsCARTHA --tezos-endorser base-dir/tezos-endorser-006-PsCARTHA \
 --rpc-addr localhost:8733 --net-addr localhost:8833 \
 --peer localhost:8832 --base-chain carthagenet
```
This script will generate the necessary files under two directories (corresponding to the two bakers):
```sh
base-dir
base-dir-b
```

Inside each of these base directories, the new node identity will be in the `base-dir/node` directory and the new Tezos account
with `baker` alias (all `tezos-client` related files will be accessible in the `base-dir/client` directory).

In general, the `baker` public keys should be provided to the chain dictator (the person who initiated
the private chain creation). This public key can be found in the `base-dir/client/public_keys` file.
After identity and account generation, this script will run `tezos-node` along
with baker and endorser daemons in the background. Once the new protocol is activated, it will start baking blocks.

To stop the bakers, do the following:
```sh
./scripts/start-baker.sh --base-dir base-dir stop
./scripts/start-baker.sh --base-dir-b base-dir stop
```

To see information about the bakers, run:

```sh
tezos-client -d base-dir/client show address baker
tezos-client -d base-dir-b/client show address baker
# add -S to see secret key as well
```

We recomend having at least two nodes and bakers in your private chain, but the more the better.

### Activating the procotol and starting the blockchain
After fetching binaries and running the baker on the dictator machine, the dictator should activate the protocol
and bake the first block by running the [`activate-protocol.sh`](./scripts/activate-protocol.sh) shell script.
After activating the new protocol and baking the first block, the private blockchain will start.

#### Editing the JSON parameter file(s)
See [this section](#modifying-the-parameter-files) in the Docker instructions for the steps required to modify the JSON parameters file.  The instructions are the same as for the non-Docker example

### Starting the blockchain
Now the blockchain is ready to be launched. In order to launch it, the dictator should run the following:
```sh
./scripts/activate-protocol.sh --base-dir base-dir --tezos-client \
  base-dir/tezos-client --parameters my-parameters.json --base-chain carthagenet
```
where my-parameters.json is the file you have just edited.

### Trying it out
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

You can either use the tezos-client which is located inside this example's Docker container or obtain one from https://github.com/serokell/tezos-packaging

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
to `fetch-binaries.sh` and `start-baker.sh` scripts.

Let's generate a new account named `bob`:
```sh
$ tezos-client gen keys bob
$ tezos-client show address bob
Hash: tz1iW2e1i355D57GSuBHw928mJkuCwcZZWmk
Public Key: edpku66KahHGQsthyuHmsYm829xnH6jWXiapkyaNf1HspXx5VKKPSu
```

And transfer some tokens:
```sh
$ tezos-client --wait none transfer 100 from alice to bob --burn-cap 0.257
```

After this, `bob` will have some tokens:
```sh
$ tezos-client get balance for bob
100.0 ꜩ
```

Note: You might have to wait a minute and rerun the previous command if you don't see the updated balance.

## Creating a peer-to-peer network

It is convenient to use a dedicated peer-to-peer network in order to run the private
blockchain.

One way to do that is to use the [ZeroTier](https://www.zerotier.com/) service.

In order to create and use the peer-to-peer network, follow these steps:

1. Create a new ZeroTier account.

2. Download the ZeroTier VPN service for your OS (Mac, Windows and Linux versions
are available).

3. Download and install the VPN service. Mac, Windows and Linux versions are available.
Once installed, your machine will be associated with a Node ID (10-digit address).


4. Go to the Network section of ZeroTier Central and create a new network.
The new network will be assotiated with a Network ID.
In order to join the Zerotier network run `sudo zerotier-cli join <network-id>`
Then, ask participants to join. Use the Node IDs that were provided for your
machine to add them to the network.

5. Ask other participants to also create a ZeroTier account and join the network you just created.

Once you have joined the network, you will be assigned an IP-address, that you can share with other
participants.

To find this IP-address, simply run `ifconfig`, the name of ZeroTier network interface
starts with `zt` prefix.
