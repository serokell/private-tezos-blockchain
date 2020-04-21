# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

FROM ubuntu

RUN apt-get update && apt-get install -y wget netbase
COPY ./scripts/ /scripts
COPY ./*.env /

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

# Args used below come from the tezos-docker.env file...
CMD /scripts/run-all.sh --peer $peer

VOLUME /base-dir
EXPOSE 8732
