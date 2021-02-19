SHELL = '/bin/bash'
export IMAGE_TAG ?= 4.0.3-2
export DOCKER_BUILDKIT?=1
export REPOSITORY?=rstudio
export REGISTRY?=593291632749.dkr.ecr.eu-west-1.amazonaws.com
export NETWORK?=default
export CHEF_LICENSE=accept-no-persist

.PHONY: build test pull push inspec up clean ps

pull:
	docker-compose push ${REPOSITORY}

build:
	docker buildx bake --load

push:
	docker-compose push ${REPOSITORY}

test: clean up
	echo Testing Container Version: ${IMAGE_TAG}
	docker-compose run --rm inspec exec tests -t docker://analytics-platform-rstudio-${REPOSITORY}_1

clean:
	docker-compose down --volumes --remove-orphans

up:
	docker-compose up -d ${REPOSITORY}

ps:
	docker-compose ps

logs:
	docker-compose logs -f ${REPOSITORY} auth-proxy

enter:
	docker-compose exec ${REPOSITORY} bash
