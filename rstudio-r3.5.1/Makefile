SHELL = '/bin/bash'
export BUILD_TAG ?= local
export DOCKER_BUILDKIT=1
export PROJECT_NAME=rstudio

.PHONY: build test

pull:
	docker-compose pull test
build:
	docker build -t quay.io/mojanalytics/${PROJECT_NAME}:${BUILD_TAG} .

test:
	echo Testing Container Version: ${BUILD_TAG}
	docker-compose --project-name ${PROJECT_NAME} up -d test
	docker-compose run --rm inspec exec tests -t docker://${PROJECT_NAME}_test_1

enter:
	docker-compose --project-name ${PROJECT_NAME} run --rm test bash

clean:
	docker-compose down
	docker-compose --project-name ${PROJECT_NAME} down
