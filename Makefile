.PHONY: static build test test-ubuntu test-debian test-rocky9 test-rocky10 clean

static:
	./scripts/static-checks.sh

build:
	docker buildx bake -f docker-bake.hcl all --load

test: test-ubuntu test-debian test-rocky9 test-rocky10

test-ubuntu:
	./scripts/build-and-test.sh ubuntu-24.04

test-debian:
	./scripts/build-and-test.sh debian-13

test-rocky9:
	./scripts/build-and-test.sh rocky-9

test-rocky10:
	./scripts/build-and-test.sh rocky-10

clean:
	docker compose -f compose.yml -f compose.systemd.yml down --remove-orphans
