FROM rocker/r-ver:3.4.0

ENV USER=rstudio
# ENV USER_NAMESPACE

ARG PANDOC_TEMPLATES_VERSION
ENV PANDOC_TEMPLATES_VERSION ${PANDOC_TEMPLATES_VERSION:-1.18}

## Add RStudio binaries to PATH
ENV PATH /usr/lib/rstudio-server/bin:$PATH

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    file \
    git \
    libapparmor1 \
    libcurl4-openssl-dev \
    libedit2 \
    libssl-dev \
    lsb-release \
    psmisc \
    python-setuptools \
    sudo \
    wget \
    rrdtool \
    openssh-client \
    libxml2-dev \
    texinfo \
    texlive \
    texlive-latex-extra \
    default-jre \
    default-jdk \
    bzip2 \
    libbz2-dev \
    libpcre3-dev \
    liblzma-dev \
    libicu-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/

# Install RStudio
RUN wget -q https://download2.rstudio.org/rstudio-server-pro-1.0.136-amd64.deb \
  && dpkg -i rstudio-server-pro-1.0.136-amd64.deb \
  && rm rstudio-server-pro-*-amd64.deb \

  # Configure RStudio
  && echo '\n\
  \nserver-access-log=1 \
  \nserver-project-sharing=0 \
  \nserver-health-check-enabled=1 \
  \nauth-proxy=1 \
  \n' >> /etc/rstudio/rserver.conf \

  # Install pandoc
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
  && wget https://github.com/jgm/pandoc-templates/archive/${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && mkdir -p /opt/pandoc/templates && tar zxf ${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
  && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates \

  ## Configure R
  && mkdir -p /etc/R \
  && echo '\n\
    \n .libPaths("~/R/library") \
    \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
    \n# is not set since a redirect to localhost may not work depending upon \
    \n# where this Docker container is running. \
    \nif(is.na(Sys.getenv("HTTR_LOCALHOST", unset=NA))) { \
    \n  options(httr_oob_default = TRUE) \
    \n}' >> /usr/local/lib/R/etc/Rprofile.site \
  && echo "PATH=\"${PATH}\"" >> /usr/local/lib/R/etc/Renviron \
  && echo "r-libs-user=~/R/library" >> /etc/rstudio/rsession.conf

# Install R Packages
RUN R -e "install.packages(c(\
    'httr', \
    'xml2', \
    'base64enc', \
    'digest', \
    'curl', \
    'aws.signature', \
    'aws.s3', \
    'evaluate', \
    'digest', \
    'formatR', \
    'highr', \
    'markdown', \
    'stringr', \
    'yaml', \
    'Rcpp', \
    'htmltools', \
    'caTools', \
    'bitops', \
    'knitr', \
    'jsonlite', \
    'base64enc', \
    'rprojroot', \
    'rmarkdown', \
    'readr', \
    'shiny' \
    ))" \

  # Install R S3 package
  && R -e "install.packages(c('aws.signature', 'aws.s3'), \
    repos = c('cloudyr' = 'http://cloudyr.github.io/drat'))" \

  # Install webshot/phantomjs for Doc/PDF with JS graphs in it
  && R -e "install.packages('webshot')" \
  && R -e "webshot::install_phantomjs()" \
  && mv /root/bin/phantomjs /usr/bin/phantomjs \
  && chmod a+rx /usr/bin/phantomjs

# Configure git
RUN git config --system credential.helper 'cache --timeout=3600' \
  && git config --system push.default simple

COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8787

CMD ["/usr/local/bin/start.sh"]
