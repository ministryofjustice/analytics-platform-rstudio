
VERSION=v1.2.1
DOCKER_IMAGE=rstudio

if [[ $VERSION =~ ^v[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then

  MINOR=${VERSION%.*}
  MAJOR=${MINOR%.*}
  TAGS="${DOCKER_IMAGE}:${MINOR},${DOCKER_IMAGE}:${MAJOR},${DOCKER_IMAGE}:latest"
# elif [ "${{ github.event_name }}" = "push" ]; then
#   TAGS="$TAGS,${DOCKER_IMAGE}:sha-${GITHUB_SHA::8}"
fi

echo $TAGS
