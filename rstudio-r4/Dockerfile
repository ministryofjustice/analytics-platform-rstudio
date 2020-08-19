FROM rocker/verse:4.0.2
LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

ARG GITHUB_PAT
ARG NCPUS=1

ENV USER="rstudio" \
    LC_ALL="en_GB.UTF-8" \
    LANG="en_GB.UTF-8" \
    DISABLE_AUTH="true"

RUN echo "${LANG} UTF-8" >> /etc/locale.gen \
    && locale-gen en_GB.utf8 \
    && update-locale LANG=${LANG} \
    && apt-get -qq update \
    && apt-get -qq install -y \
    build-essential \
    bzip2 \
    gnupg2 \
    nano \
    && rm -rf /var/lib/apt/lists/*
