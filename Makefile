SHELL = '/bin/bash'
export BUILD_TAG ?= latest
export DOCKER_BUILDKIT=1
export PROJECT_NAME=rstudio

.PHONY: build test

pull:
	docker-compose pull test
build:
	docker build -t quay.io/mojanalytics/${PROJECT_NAME}:${BUILD_TAG} .

test:
	docker-compose --project-name ${PROJECT_NAME} down
	docker-compose --project-name ${PROJECT_NAME} up -d
	inspec exec tests -t docker://${PROJECT_NAME}_test_1
	docker-compose stop

enter:
	docker-compose down
	docker-compose --project-name ${PROJECT_NAME} up -d
	docker-compose --project-name ${PROJECT_NAME} run --rm test bash
