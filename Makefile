SHELL = '/bin/bash'
export IMAGE_TAG ?= 4.1.2
export DOCKER_BUILDKIT?=1
export REPOSITORY?=rstudio
export REGISTRY?=593291632749.dkr.ecr.eu-west-1.amazonaws.com
export NETWORK?=default
export CHEF_LICENSE=accept-no-persist

.PHONY: build test pull push inspec up clean ps

pull:
	docker-compose pull

push:
	docker push ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

build:
	docker build --network=${NETWORK} -t ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG} .

test: up
	echo Testing Container Version: ${IMAGE_TAG}
	docker-compose build --no-cache test_files
	docker-compose up -d test_files
	docker-compose run --rm inspec check tests
	docker-compose run --rm inspec exec tests -t docker://analytics-platform-${REPOSITORY}_${REPOSITORY}_1

clean:
	docker-compose down --volumes --remove-orphans

up:
	docker-compose up -d rstudio auth-proxy

ps:
	docker-compose ps

logs:
	docker-compose logs -f ${REPOSITORY} auth-proxy

enter:
	docker-compose exec inspec bash
