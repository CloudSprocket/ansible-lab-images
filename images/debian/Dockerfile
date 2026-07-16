# syntax=docker/dockerfile:1.18@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

ARG BASE_TARGET=ubuntu-24.04

FROM docker.io/library/ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90 AS ubuntu-24.04
FROM docker.io/library/debian:13@sha256:fac46bff2e02f51425b6e33b0e1169f55dfb053d83511ca28aa50c09fd5ed7a4 AS debian-13

FROM ${BASE_TARGET} AS managed-node

ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV container=docker \
    LANG=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       curl \
       dbus \
       iproute2 \
       openssh-server \
       procps \
       python3 \
       python3-apt \
       sudo \
       systemd \
       systemd-sysv \
       tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash learner \
    && usermod --append --groups sudo learner \
    && usermod --password '*' learner \
    && printf '%s\n' 'learner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-lab-user \
    && chmod 0440 /etc/sudoers.d/90-lab-user

COPY --chmod=0755 common/entrypoint.sh /usr/local/bin/lab-entrypoint
COPY --chmod=0600 common/sshd_config /etc/ssh/sshd_config
COPY --chmod=0755 common/systemd/mask-common-units.sh /usr/local/sbin/mask-common-units

RUN systemctl disable ssh.socket >/dev/null 2>&1 || true \
    && systemctl enable ssh.service \
    && /usr/local/sbin/mask-common-units \
    && rm -f /etc/ssh/ssh_host_* \
    && install -d -m 0755 /run/sshd

EXPOSE 22
STOPSIGNAL SIGRTMIN+3
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
  CMD ["sh", "-c", "pgrep -x sshd >/dev/null"]
ENTRYPOINT ["/usr/local/bin/lab-entrypoint"]
