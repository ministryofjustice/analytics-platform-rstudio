# checkov:skip=CKV_DOCKER_2:Healthcheck instructions have not been added to container images
# checkov:skip=CKV_DOCKER_3:"Ensure that a user for the container has been created"

FROM rocker/rstudio:4.6.2
LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

ENV CRAN="https://p3m.dev/cran/__linux__/resolute/latest"

COPY secure-cookie-key.sh /etc/cont-init.d/secure-cookie-key-conf
COPY default_user.patch /tmp/default_user.patch

ENV LC_ALL="en_GB.UTF-8" \
    LANG="en_GB.UTF-8" \
    DISABLE_AUTH="true" \
    EDITOR="nano"

ENV QUARTO_VERSION="1.11.9" \
    GIT_LFS_VERSION="3.8.1" \
    GIT_LFS_VERSION_SHA="e72cf723a4a660438862282e8aecf3885fc8123e88bfcad534cf6b941a354b75" \
    GITHUB_CLI_VERSION="2.103.3" \
    GITHUB_COPILOT_CLI_VERSION="1.0.105"

# Keep Ubuntu packages unpinned so builds receive current security updates.
# Retry the full update/upgrade/install so a mirror caught mid-publish
# (index lists a package the pool can't serve yet) gets a fresh index.
# hadolint ignore=DL3008
RUN set -eu \
  && echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_GB.utf8 \
  && update-locale LANG=en_GB.UTF-8 \
  && echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/80-retries \
  && for attempt in 1 2 3; do \
       if apt-get update \
          && apt-get upgrade -y \
          && apt-get install -y \
               curl \
               nano \
               python3 \
               python3-pip \
               python3-venv \
               python3-pandas \
               libxml2-dev \
               libgdal-dev \
               libglpk-dev \
               libudunits2-dev \
               libpoppler-cpp-dev \
               libfreetype6-dev \
               libgeos-dev \
               libproj-dev \
               openssh-client \
               libfontconfig1-dev \
               libnlopt-dev \
               cmake \
               libharfbuzz-dev \
               libfribidi-dev \
               libgit2-dev \
               ca-certificates-java \
               openjdk-8-jdk \
               pandoc \
               gdebi-core \
               libcairo2-dev \
               libgsl-dev; \
       then break; fi; \
       if [ "$attempt" -eq 3 ]; then echo "apt failed after 3 attempts" >&2; exit 1; fi; \
       echo "apt attempt $attempt failed, retrying in 60s" >&2; \
       rm -rf /var/lib/apt/lists/*; \
       sleep 60; \
     done \
  && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 &&\
  update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10 &&\
  command -v python &&\
  command -v pip
  
ARG TARGETARCH
# Patch GHSA-mrhx-c7xc-m3w5 until the RStudio base image bundles a fixed Zod.
RUN curl --location --fail-with-body \
      "https://registry.npmjs.org/zod/-/zod-4.6.6.tgz" \
      --output /tmp/zod.tgz \
    && printf '%s\n' "e149b34141797f1bdf7181e56e30667a353ec3e85b0e7585c78692f24071ee73c11dc3b64aa3dba401bcb276dd83e5ec7b8a5179f47df2182316020c088fd484  /tmp/zod.tgz" > /tmp/zod.sha512 \
    && sha512sum --check --strict /tmp/zod.sha512 \
    && test -f /usr/lib/rstudio-server/bin/copilot-language-server-js/node_modules/zod/package.json \
    && python3 -m tarfile --extract /tmp/zod.tgz /tmp/zod --filter data \
    && rm -rf /usr/lib/rstudio-server/bin/copilot-language-server-js/node_modules/zod \
    && mv /tmp/zod/package /usr/lib/rstudio-server/bin/copilot-language-server-js/node_modules/zod \
    && rmdir /tmp/zod \
    && rm /tmp/zod.tgz /tmp/zod.sha512

# GitHub CLI
RUN curl --location --fail-with-body \
      "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
      --output "githubcli-archive-keyring.gpg" \
    && install -D --owner root --group root --mode 644 githubcli-archive-keyring.gpg /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y "gh=${GITHUB_CLI_VERSION}" \
    && rm -rf /var/lib/apt/lists/* githubcli-archive-keyring.gpg

# GitHub Copilot CLI
RUN curl --location --fail-with-body \
      "https://github.com/github/copilot-cli/releases/download/v${GITHUB_COPILOT_CLI_VERSION}/copilot-linux-x64.tar.gz" \
      --output "copilot.tar.gz" \
    && tar --extract --file copilot.tar.gz \
    && install --owner nobody --group nogroup --mode 0755 copilot /usr/local/bin/copilot \
    && rm -rf copilot.tar.gz copilot

RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.deb \
 && gdebi --non-interactive quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.deb

RUN patch /rocker_scripts/default_user.sh /tmp/default_user.patch

RUN echo '\nulimit -S -c 0' >> /etc/profile

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
