# SPDX-FileCopyrightText: 2019 TQ Tezos <https://tqtezos.com/>
#
# SPDX-License-Identifier: MPL-2.0
FROM ubuntu
RUN apt-get update && apt-get install -y wget netbase
COPY ./scripts/ /scripts
RUN mkdir /base-dir
VOLUME /base-dir
ENTRYPOINT ["/scripts/docker.sh"]
EXPOSE 8732
CMD []
