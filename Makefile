SHELL = '/bin/bash'
export IMAGE_TAG ?= local
export DOCKER_BUILDKIT?=1
export REPOSITORY?=rstudio
export REGISTRY?=mojanalytics
export NETWORK?=default

.PHONY: build test

pull:
	docker pull ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

build:
	docker build --network=${NETWORK} -t ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG} .

push:
	docker push ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

inspec:
	docker-compose --project-name ${REPOSITORY} up -d test
	docker-compose --project-name ${REPOSITORY} run --rm inspec check tests

test: #clean
	echo Testing Container Version: ${IMAGE_TAG}
	ls
	ls files
	docker run -v ${PWD}:/share -e CHEF_LICENSE=accept-no-persist --entrypoint "ls" --rm chef/inspec:current /share
	docker run -v ${PWD}/tests:/share/tests -e CHEF_LICENSE=accept-no-persist --entrypoint "ls" --rm chef/inspec:current -la /share/tests/files


test_old:
	# docker-compose --project-name ${REPOSITORY} up -d test
	# docker-compose --project-name ${REPOSITORY} run --rm inspec exec tests -t docker://${REPOSITORY}_test_1

enter:
	docker-compose --project-name ${REPOSITORY} run --rm test bash

clean:
	docker-compose down
	docker-compose --project-name ${REPOSITORY} down
