# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

# Docker build args - those without defaults are required:
# e.g. docker build \
#  --build-arg genesis_key=
#  --build-arg peer=
#  --build-arg encrypted=false

ARG peer
ARG genesis_key
ARG encrypted=true
ARG net_addr_port=8733
ARG rpc_addr_port=8732

FROM ubuntu

RUN apt-get update && apt-get install -y wget netbase
COPY ./scripts/ /scripts

RUN mkdir /base-dir
RUN mkdir /base-dir/client
RUN mkdir /base-dir/node

ARG prefix=https://github.com/serokell/tezos-packaging/releases/download/202004061400
RUN wget $prefix/tezos-client -P "$base_dir/"
RUN wget $prefix/tezos-node -P "$base_dir/"
RUN wget $prefix/tezos-endorser-006-PsCARTHA -P "$base_dir/"
RUN wget $prefix/tezos-baker-006-PsCARTHA -P "$base_dir/"

RUN chmod +x "$base_dir"/tezos-*

CMD /scripts/start-baker.sh \
    --base-dir /base-dir \
    --tezos-client /base-dir/tezos-client \
    --tezos-node /base-dir/tezos-node
    --tezos-baker "/base-dir/tezos-baker-"* \
    --tezos-endorser "/base-dir/tezos-endorser-"* \
    --net-addr ":$net_addr_port" \
    --rpc-addr ":$rpc_addr_port" \
    --no-background-node \
    --peer $peer \
    --encrypted $encrypted

VOLUME /base-dir
EXPOSE 8732
