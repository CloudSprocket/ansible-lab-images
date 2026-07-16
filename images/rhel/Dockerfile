# syntax=docker/dockerfile:1.18@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

ARG BASE_TARGET=rocky-9

FROM docker.io/rockylinux/rockylinux:9@sha256:8101994123cf3d0a8fee517bee7f39e555c7d92bd2d9eb3303cc988a0eeed00f AS rocky-9
FROM docker.io/rockylinux/rockylinux:10@sha256:827d37bc128288ccf160ee318bb3cb92d591164cb217e92f8bc61e3982ae1834 AS rocky-10

FROM ${BASE_TARGET} AS managed-node

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV container=docker \
    LANG=C.UTF-8

RUN dnf -y upgrade --refresh \
    && dnf -y install \
       bash \
       ca-certificates \
       curl-minimal \
       dbus \
       iproute \
       openssh-server \
       procps-ng \
       python3 \
       python3-dnf \
       shadow-utils \
       sudo \
       systemd \
       tzdata \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN useradd --create-home --shell /bin/bash learner \
    && usermod --append --groups wheel learner \
    && passwd --lock learner \
    && printf '%s\n' 'learner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-lab-user \
    && chmod 0440 /etc/sudoers.d/90-lab-user

COPY --chmod=0755 common/entrypoint.sh /usr/local/bin/lab-entrypoint
COPY --chmod=0600 common/sshd_config /etc/ssh/sshd_config
COPY --chmod=0755 common/systemd/mask-common-units.sh /usr/local/sbin/mask-common-units

RUN systemctl enable sshd.service \
    && /usr/local/sbin/mask-common-units \
    && rm -f /etc/ssh/ssh_host_* \
    && install -d -m 0755 /run/sshd

EXPOSE 22
STOPSIGNAL SIGRTMIN+3
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=12 \
  CMD ["sh", "-c", "pgrep -x sshd >/dev/null"]
ENTRYPOINT ["/usr/local/bin/lab-entrypoint"]
