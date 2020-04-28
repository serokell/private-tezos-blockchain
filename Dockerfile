# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0

FROM ubuntu as builder

RUN apt-get update && apt-get install -y wget netbase
ARG base_dir=/opt/tezos
RUN mkdir -p $base_dir/client
RUN mkdir -p $base_dir/node
RUN mkdir -p $base_dir/bin

RUN wget https://github.com/serokell/tezos-packaging/releases/download/202004061400/binaries-0737ae7a.tar.gz
RUN tar -xvzf binaries-0737ae7a.tar.gz -C /opt/tezos/bin

FROM ubuntu
COPY --from=builder /opt/tezos /opt/tezos
