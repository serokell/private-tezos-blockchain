# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

FROM ubuntu

RUN apt-get update && apt-get install -y wget netbase
COPY ./scripts/ /scripts
COPY ./parameters.json /

ARG base_dir=/base-dir
RUN mkdir $base_dir
RUN mkdir $base_dir/client
RUN mkdir $base_dir/node

ARG prefix=https://github.com/serokell/tezos-packaging/releases/download/202004061400
RUN wget $prefix/tezos-client -P "$base_dir/"
RUN wget $prefix/tezos-node -P "$base_dir/"
RUN wget $prefix/tezos-endorser-006-PsCARTHA -P "$base_dir/"
RUN wget $prefix/tezos-baker-006-PsCARTHA -P "$base_dir/"

RUN chmod +x "$base_dir"/tezos-*

CMD /scripts/start-baker.sh \
    --base-dir /base-dir \
    --tezos-client /base-dir/tezos-client \
    --tezos-node /base-dir/tezos-node \
    --tezos-baker /base-dir/tezos-baker \
    --tezos-endorser /base-dir/tezos-endorser \
    --net-addr :8732 \
    --rpc-addr :8733 \
    --no-background-node

VOLUME /base-dir
EXPOSE 8732
