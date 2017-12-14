FROM rocker/rstudio-stable:3.4.2

ENV USER=rstudio

# Select Debian mirror.  
# This is needed because e.g. default-jdk doesn't seem to be available through the default mirror
RUN sed -i 's%deb.debian.org%mirror.bytemark.co.uk%' /etc/apt/sources.list

# Set locale
RUN apt-get update \
  && apt-get install -y --no-install-recommends locales \
  && echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_GB.utf8 \
  && /usr/sbin/update-locale LANG=en_GB.UTF-8 \
  && rm -rf /var/lib/apt/lists/*
ENV LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8


# apt-get in our current dockerfile which are not in rocker/rstudio
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  bzip2 \
  default-jre \
  default-jdk \
  libgdal-dev \
  libgeos-dev \
  libglpk-dev \
  libpoppler-cpp-dev \
  libproj-dev \
  libxml2-dev \
  lmodern \
  openssh-client \
  rrdtool \
  texlive \
  texlive-latex-extra \
  vim \
  && rm -rf /var/lib/apt/lists/* \ 
  && wget -O libssl1.0.0.deb http://ftp.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u6_amd64.deb \
  && dpkg -i libssl1.0.0.deb \  
  && rm libssl1.0.0.deb

# Configure R Studio to max out at 12 Gb of memory
RUN echo '\n\ 
  \n[*] \ 
  \nmax-memory-mb = 12288 \
  \n' >> /etc/rstudio/profiles

# Install R Packages
RUN R -e "install.packages(c(\
    'Rcpp', \
    'aws.s3', \
    'aws.signature', \
    'base64enc', \
    'base64enc', \
    'bitops', \
    'caTools', \
    'codetools', \
    'curl', \
    'devtools', \
    'digest', \
    'digest', \
    'evaluate', \
    'formatR', \
    'highr', \
    'htmltools', \
    'httr', \
    'jsonlite', \
    'knitr', \
    'markdown', \
    'packrat', \
    'readr', \
    'rmarkdown', \
    'rprojroot', \
    'shiny', \
    'stringr', \
    'tidyverse', \
    'xml2', \
    'yaml' \
    ))" \

  # Install R S3 package
  && R -e "install.packages(c('aws.signature', 'aws.s3', 'aws.ec2metadata'), \
    repos = c('cloudyr' = 'http://cloudyr.github.io/drat'))" \

  # Install MOJ S3tools package
  && R -e "devtools::install_github('moj-analytical-services/s3tools')" \
  && R -e "devtools::install_github('moj-analytical-services/s3browser')" \

  # Install webshot/phantomjs for Doc/PDF with JS graphs in it
  && R -e "install.packages('webshot')" \
  && R -e "webshot::install_phantomjs()" \
  && mv /root/bin/phantomjs /usr/bin/phantomjs \
  && chmod a+rx /usr/bin/phantomjs

COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8787

CMD ["/usr/local/bin/start.sh"]
