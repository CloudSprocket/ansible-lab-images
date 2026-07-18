variable "UBUNTU_2404_IMAGE" {
  default = "docker.io/cloudsprocket/ansible-node-ubuntu-2404"
}

variable "DEBIAN_13_IMAGE" {
  default = "docker.io/cloudsprocket/ansible-node-debian-13"
}

variable "ROCKY_9_IMAGE" {
  default = "docker.io/cloudsprocket/ansible-node-rocky-9"
}

variable "ROCKY_10_IMAGE" {
  default = "docker.io/cloudsprocket/ansible-node-rocky-10"
}

variable "CONTROLLER_IMAGE" {
  default = "docker.io/cloudsprocket/ansible-controller"
}

variable "VERSION" {
  default = "dev"
}

variable "REVISION" {
  default = "local"
}

variable "CREATED" {
  default = "1970-01-01T00:00:00Z"
}

variable "SOURCE_URL" {
  default = "https://github.com/CloudSprocket/ansible-lab-images"
}

variable "UBUNTU_BASE_DIGEST" {
  default = "sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90"
}

variable "DEBIAN_BASE_DIGEST" {
  default = "sha256:fac46bff2e02f51425b6e33b0e1169f55dfb053d83511ca28aa50c09fd5ed7a4"
}

variable "ROCKY9_BASE_DIGEST" {
  default = "sha256:8101994123cf3d0a8fee517bee7f39e555c7d92bd2d9eb3303cc988a0eeed00f"
}

variable "ROCKY10_BASE_DIGEST" {
  default = "sha256:827d37bc128288ccf160ee318bb3cb92d591164cb217e92f8bc61e3982ae1834"
}

variable "PYTHON_BASE_DIGEST" {
  default = "sha256:cea0e6040540fb2b965b6e7fb5ffa00871e632eef63719f0ea54bca189ce14a6"
}

group "default" {
  targets = ["ubuntu-2404", "debian-13"]
}

group "all" {
  targets = ["ubuntu-2404", "debian-13", "rocky-9", "rocky-10", "controller"]
}

group "test" {
  targets = ["ubuntu-2404", "debian-13", "rocky-9", "rocky-10", "controller"]
}

group "release" {
  targets = [
    "release-ubuntu-2404",
    "release-debian-13",
    "release-rocky-9",
    "release-rocky-10",
    "release-controller",
  ]
}

target "_common" {
  context = "."
  platforms = ["linux/amd64", "linux/arm64"]
  labels = {
    "org.opencontainers.image.created" = CREATED
    "org.opencontainers.image.description" = "Disposable Linux managed node for Ansible labs and testing"
    "org.opencontainers.image.licenses" = "MIT"
    "org.opencontainers.image.revision" = REVISION
    "org.opencontainers.image.source" = SOURCE_URL
    "org.opencontainers.image.title" = "CloudSprocket Ansible managed node"
    "org.opencontainers.image.url" = SOURCE_URL
    "org.opencontainers.image.version" = VERSION
  }
}

target "ubuntu-2404" {
  inherits = ["_common"]
  dockerfile = "images/debian/Dockerfile"
  args = {
    BASE_TARGET = "ubuntu-24.04"
  }
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket Ansible managed node: Ubuntu 24.04"
    "org.opencontainers.image.description" = "Disposable Ubuntu 24.04 managed node for Ansible labs and testing"
    "org.opencontainers.image.base.digest" = UBUNTU_BASE_DIGEST
    "org.opencontainers.image.base.name" = "docker.io/library/ubuntu:24.04"
    "org.cloudsprocket.image.distribution" = "ubuntu"
    "org.cloudsprocket.image.distribution-version" = "24.04"
    "org.cloudsprocket.image.supported-until" = "2029-05-31"
  }
  tags = ["${UBUNTU_2404_IMAGE}:dev"]
}

target "debian-13" {
  inherits = ["_common"]
  dockerfile = "images/debian/Dockerfile"
  args = {
    BASE_TARGET = "debian-13"
  }
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket Ansible managed node: Debian 13"
    "org.opencontainers.image.description" = "Disposable Debian 13 managed node for Ansible labs and testing"
    "org.opencontainers.image.base.digest" = DEBIAN_BASE_DIGEST
    "org.opencontainers.image.base.name" = "docker.io/library/debian:13"
    "org.cloudsprocket.image.distribution" = "debian"
    "org.cloudsprocket.image.distribution-version" = "13"
    "org.cloudsprocket.image.supported-until" = "2030-06-30"
  }
  tags = ["${DEBIAN_13_IMAGE}:dev"]
}

target "rocky-9" {
  inherits = ["_common"]
  dockerfile = "images/rhel/Dockerfile"
  args = {
    BASE_TARGET = "rocky-9"
  }
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket Ansible managed node: Rocky Linux 9"
    "org.opencontainers.image.description" = "Disposable Rocky Linux 9 managed node for Ansible labs and testing"
    "org.opencontainers.image.base.digest" = ROCKY9_BASE_DIGEST
    "org.opencontainers.image.base.name" = "docker.io/rockylinux/rockylinux:9"
    "org.cloudsprocket.image.distribution" = "rocky"
    "org.cloudsprocket.image.distribution-version" = "9"
    "org.cloudsprocket.image.supported-until" = "2032-05-31"
  }
  tags = ["${ROCKY_9_IMAGE}:dev"]
}

target "rocky-10" {
  inherits = ["_common"]
  dockerfile = "images/rhel/Dockerfile"
  args = {
    BASE_TARGET = "rocky-10"
  }
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket Ansible managed node: Rocky Linux 10"
    "org.opencontainers.image.description" = "Disposable Rocky Linux 10 managed node for Ansible labs and testing"
    "org.opencontainers.image.base.digest" = ROCKY10_BASE_DIGEST
    "org.opencontainers.image.base.name" = "docker.io/rockylinux/rockylinux:10"
    "org.cloudsprocket.image.distribution" = "rocky"
    "org.cloudsprocket.image.distribution-version" = "10"
    "org.cloudsprocket.image.supported-until" = "2035-05-31"
  }
  tags = ["${ROCKY_10_IMAGE}:dev"]
}

target "controller" {
  inherits = ["_common"]
  dockerfile = "images/controller/Dockerfile"
  labels = {
    "org.opencontainers.image.title" = "CloudSprocket Ansible controller"
    "org.opencontainers.image.description" = "Ansible control node with ansible-core, ansible-lint and common collections for lab use"
    "org.opencontainers.image.base.digest" = PYTHON_BASE_DIGEST
    "org.opencontainers.image.base.name" = "docker.io/library/python:3.14-slim"
    "org.cloudsprocket.image.ansible-core" = "2.21.2"
  }
  tags = ["${CONTROLLER_IMAGE}:dev"]
}

target "release-ubuntu-2404" {
  inherits = ["ubuntu-2404"]
  tags = [
    "${UBUNTU_2404_IMAGE}:latest",
    "${UBUNTU_2404_IMAGE}:${VERSION}",
  ]
}

target "release-debian-13" {
  inherits = ["debian-13"]
  tags = [
    "${DEBIAN_13_IMAGE}:latest",
    "${DEBIAN_13_IMAGE}:${VERSION}",
  ]
}

target "release-rocky-9" {
  inherits = ["rocky-9"]
  tags = [
    "${ROCKY_9_IMAGE}:latest",
    "${ROCKY_9_IMAGE}:${VERSION}",
  ]
}

target "release-rocky-10" {
  inherits = ["rocky-10"]
  tags = [
    "${ROCKY_10_IMAGE}:latest",
    "${ROCKY_10_IMAGE}:${VERSION}",
  ]
}

target "release-controller" {
  inherits = ["controller"]
  tags = [
    "${CONTROLLER_IMAGE}:latest",
    "${CONTROLLER_IMAGE}:${VERSION}",
  ]
}
