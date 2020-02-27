# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0
FROM ubuntu
RUN apt-get update && apt-get install -y rsync git m4 build-essential patch unzip \
  bubblewrap wget pkg-config libgmp-dev libev-dev libhidapi-dev
RUN wget https://github.com/ocaml/opam/releases/download/2.0.3/opam-2.0.3-x86_64-linux && \
  cp opam-2.0.3-x86_64-linux /usr/local/bin/opam && chmod a+x /usr/local/bin/opam
COPY ./scripts/ /scripts
COPY ./patches/ /patches
RUN mkdir /base-dir
VOLUME /base-dir
ENTRYPOINT ["/scripts/docker.sh"]
EXPOSE 8732
CMD []
