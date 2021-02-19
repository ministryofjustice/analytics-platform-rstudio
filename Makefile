SHELL = '/bin/bash'
export IMAGE_TAG ?= 4.0.3-2
export DOCKER_BUILDKIT?=1
export REPOSITORY?=rstudio
export REGISTRY?=593291632749.dkr.ecr.eu-west-1.amazonaws.com
export NETWORK?=default
export CHEF_LICENSE=accept-no-persist

.PHONY: build test pull push inspec up clean ps

pull:
	docker-compose pull ${REPOSITORY}

build:
	docker buildx bake --load

push:
	docker-compose push ${REPOSITORY}

test: up
	echo Testing Container Version: ${IMAGE_TAG}
	docker-compose --project-name ${REPOSITORY} up -d test_files
	docker-compose --project-name ${REPOSITORY} run --rm inspec check tests
	docker-compose --project-name ${REPOSITORY} run --rm inspec exec tests -t docker://${REPOSITORY}_${REPOSITORY}_1

clean:
	docker-compose down --volumes --remove-orphans
	docker-compose --project-name ${REPOSITORY} down --volumes --remove-orphans

up:
	docker-compose --project-name ${REPOSITORY} up -d ${REPOSITORY}

ps:
	docker-compose --project-name ${REPOSITORY} ps

logs:
	docker-compose --project-name ${REPOSITORY} logs -f ${REPOSITORY} auth-proxy

enter:
	docker-compose --project-name ${REPOSITORY} exec inspec bash
