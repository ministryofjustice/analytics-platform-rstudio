# checkov:skip=CKV_DOCKER_2:Healthcheck instructions have not been added to container images
# checkov:skip=CKV_DOCKER_3:"Ensure that a user for the container has been created"

FROM rocker/rstudio:4.6.0
LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

# set default CRAN
ENV CRAN="https://p3m.dev/cran/__linux__/noble/latest"

COPY secure-cookie-key.sh /etc/cont-init.d/secure-cookie-key-conf
COPY default_user.patch /tmp/default_user.patch

ENV LC_ALL="en_GB.UTF-8" \
  LANG="en_GB.UTF-8" \
  DISABLE_AUTH="true" \
  EDITOR="nano"

ENV QUARTO_VERSION="1.7.31"

RUN echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_GB.utf8 \
  && update-locale LANG=en_GB.UTF-8 \
  && apt-get update && apt-get install -y && apt-get upgrade -y\
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
  libgsl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 &&\
  update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10 &&\
  command -v python &&\
  command -v pip

ARG TARGETARCH
RUN curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.deb \
 && gdebi --non-interactive quarto-${QUARTO_VERSION}-linux-${TARGETARCH}.deb

RUN patch /rocker_scripts/default_user.sh /tmp/default_user.patch

RUN echo '\nulimit -S -c 0' >> /etc/profile

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
