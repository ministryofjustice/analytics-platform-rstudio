SHELL = '/bin/bash'
export IMAGE_TAG ?= local
export DOCKER_BUILDKIT?=1
export REPOSITORY?=rstudio
export REGISTRY?=mojanalytics
export NETWORK?=default
export CHEF_LICENSE=accept-no-persist

.PHONY: build test pull push inspec up clean

pull:
	docker pull ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

build:
	docker-compose build tests
	docker build --network=${NETWORK} -t ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG} .

push:
	docker push ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

inspec: #clean
	# docker-compose --project-name ${REPOSITORY} up -d test
	# docker-compose --project-name ${REPOSITORY} run --entrypoint sh --rm inspec
	docker-compose --project-name ${REPOSITORY} run --entrypoint sh --rm test
	# docker-compose --project-name ${REPOSITORY} run --rm inspec check tests
	# inspec exec tests -t docker://${REPOSITORY}_test_1

test: clean build up
	echo Testing Container Version: ${IMAGE_TAG}
	docker-compose --project-name ${REPOSITORY} run --rm inspec exec tests -t docker://${REPOSITORY}_test_1

enter:
	# docker-compose --project-name ${REPOSITORY} --entrypoint bash run --rm inspec

clean:
	docker-compose down
	docker-compose --project-name ${REPOSITORY} down
	# docker volume rm rstudio_tests

up:
	docker-compose --project-name ${REPOSITORY} up -d tests test
