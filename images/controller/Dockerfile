# syntax=docker/dockerfile:1.18@sha256:dabfc0969b935b2080555ace70ee69a5261af8a8f1b4df97b9e7fbcf6722eddf

FROM docker.io/library/python:3.14-slim@sha256:d3400aa122fa42cf0af0dbe8ec3091b047eac5c8f7e3539f7135e86d855dc015

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PATH=/opt/ansible/bin:${PATH} \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY images/controller/requirements.txt /tmp/requirements.txt
COPY images/controller/requirements.yml /tmp/requirements.yml

RUN python -m venv /opt/ansible \
    && /opt/ansible/bin/pip install --no-cache-dir --no-compile \
       --requirement /tmp/requirements.txt \
    && /opt/ansible/bin/ansible-galaxy collection install \
       -r /tmp/requirements.yml \
       -p /usr/share/ansible/collections \
    && rm -f /tmp/requirements.txt /tmp/requirements.yml

RUN useradd --create-home --shell /bin/bash automation

COPY --chmod=0755 images/controller/entrypoint.sh /usr/local/bin/controller-entrypoint

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/controller-entrypoint"]
CMD ["/bin/bash"]
