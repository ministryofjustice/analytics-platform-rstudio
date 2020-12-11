SHELL = '/bin/bash'
export IMAGE_TAG ?= local
export DOCKER_BUILDKIT?=1
export REPOSITORY?=rstudio
export REGISTRY?=mojanalytics
export NETWORK?=default
export CHEF_LICENSE=accept-no-persist

.PHONY: build test pull push up clean

pull:
	docker pull ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

build:
	docker buildx build -f Dockerfile.tests . -t ${REGISTRY}/${REPOSITORY}-test:${IMAGE_TAG} --load --network=${NETWORK}
	@echo "Showing Conda Spec"
	docker run -it --rm ${REGISTRY}/${REPOSITORY}-test:${IMAGE_TAG} cat /tests/controls/conda_spec.rb
	docker buildx build -f Dockerfile . -t ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG} --load --network=${NETWORK}

push:
	docker push ${REGISTRY}/${REPOSITORY}:${IMAGE_TAG}

clean:
	docker-compose --project-name ${REPOSITORY} down
	docker volume rm -f rstudio_tests

up:
	docker-compose --project-name ${REPOSITORY} up -d tests test

test: clean up
	echo Testing Container Version: ${IMAGE_TAG}
	docker-compose --project-name ${REPOSITORY} run --rm inspec exec tests -t docker://${REPOSITORY}_test_1

bake:
	docker buildx bake --load
