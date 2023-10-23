ARM_DOCKER=Dockerfile.arm
AMD_DOCKER=Dockerfile.amd
DOCKER_NAME=buildme

arm: $(ARM_DOCKER)
	docker build --file $(ARM_DOCKER) -t $(DOCKER_NAME) .

amd: $(AMD_DOCKER)
	docker build --file $(AMD_DOCKER) -t $(DOCKER_NAME) .

.PHONY: arm amd
