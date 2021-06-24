FROM rocker/rstudio:4.0.5
LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

COPY secure-cookie-key.sh /etc/cont-init.d/secure-cookie-key-conf
COPY userconf.patch /userconf.patch

ENV LC_ALL="en_GB.UTF-8" \
  LANG="en_GB.UTF-8" \
  DISABLE_AUTH="true" \
  EDITOR="nano"

RUN echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_GB.utf8 \
  && update-locale LANG=en_GB.UTF-8 \
  && apt-get update && apt-get install -y \
  curl \
  nano \
  python3 \
  python3-pip \
  python3-pandas \
  libxml2-dev \
  libgdal-dev \
  libudunits2-dev \
  libgeos-dev \
  libproj-dev \
  openssh-client \
  && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10 &&\
  update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10 &&\
  command -v python &&\
  command -v pip

RUN patch -u /rocker_scripts/userconf.sh -i /userconf.patch \
  && cp /rocker_scripts/userconf.sh /etc/cont-init.d/userconf
