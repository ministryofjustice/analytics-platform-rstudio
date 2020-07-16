SHELL = '/bin/bash'
export BUILD_TAG ?= 1.2.1335-r3.5.1-python3.7.1-conda-10
export DOCKER_BUILDKIT=1
export PROJECT_NAME=rstudio

.PHONY: build test

pull:
	docker-compose pull test
build: pull
	# docker build -t quay.io/mojanalytics/${PROJECT_NAME}:${BUILD_TAG} .

test:
	docker-compose down
	docker-compose --project-name ${PROJECT_NAME} up -d
	docker-compose run --rm inspec exec tests -t docker://rstudio_test_1
	# inspec exec tests -t docker://${PROJECT_NAME}_test_1

enter:
	docker-compose down
	docker-compose --project-name ${PROJECT_NAME} up -d
	docker-compose --project-name ${PROJECT_NAME} run --rm test bash
