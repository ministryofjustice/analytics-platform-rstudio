FROM rocker/verse:3.5.3@sha256:7cf4253239c338fbef924ddf46b7632cc52d1da7616e3d80b11bca0093071cb2
LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

ARG GITHUB_PAT
ARG NCPUS=1

# R version 3.5.3 is not available via Conda, sticking to 3.5.1
# ENV R_VERSION=${R_VERSION:-3.5.1}
ENV R_VERSION=3.5.1 \
    PY_VERSION=${PY_VERSION:-3.7} \
    USER=rstudio \
    LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8 \
    PATH=/opt/conda/bin:$PATH

## Set locale & install packages
RUN echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_GB.utf8 \
    && update-locale LANG=en_GB.UTF-8 \
    && apt-get -qq update \
    && apt-get -qq install -y \
    alien \
    build-essential \
    bzip2 \
    ca-certificates \
    cargo \
    curl \
    git \
    gnupg2 \
    locales \
    nano \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install texlive with LaTex binaries and tools (scheme-basic)
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
    && mkdir /install-tl-unx \
    && tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1 \
    && echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile \
    && /install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile \
    && rm -r /install-tl-unx \
    && rm install-tl-unx.tar.gz

# Install SimbaAthena & configure ODBC drivers
RUN wget -q https://s3.amazonaws.com/athena-downloads/drivers/ODBC/SimbaAthenaODBC_1.0.3/Linux/simbaathena-1.0.3.1004-1.x86_64.rpm -P /tmp \
    && alien -i /tmp/simbaathena-1.0.3.1004-1.x86_64.rpm \
    && rm -f /tmp/simbaathena-1.0.3.1004-1.x86_64.rpm
COPY files/odbc* /etc/

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/conda \
    && rm ~/miniconda.sh \
    && /opt/conda/bin/conda clean -tipsy \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# Configure R
COPY files/.condarc /opt/conda/
RUN conda install python=$PY_VERSION r-base=$R_VERSION
RUN echo '.libPaths(c("~/R/library",paste0(R.home(), "/library"), .libPaths()))' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo "PATH=\"${PATH}\"" >> /usr/local/lib/R/etc/Renviron \
    && echo "AWS_DEFAULT_REGION=eu-west-1" >> /usr/local/lib/R/etc/Renviron \
    && echo "r-libs-user=~/R/library" >> /etc/rstudio/rsession.conf

# Install Conda Packages
RUN conda config --system --set pip_interop_enabled True \
    && conda install \
    boto3 \
    r-aws.s3 \
    r-aws.ec2metadata \
    r-Rcpp \
    r-base64enc \
    r-bitops \
    r-caTools \
    r-codetools \
    r-curl \
    r-devtools \
    r-digest \
    r-evaluate \
    r-formatR \
    r-highr \
    r-htmltools \
    r-httr \
    r-jsonlite \
    r-knitr \
    r-markdown \
    r-packrat \
    r-readr \
    r-reticulate \
    r-rmarkdown \
    r-rprojroot \
    r-shiny \
    r-stringr \
    r-s3tools \
    r-tidyverse \
    r-webshot \
    r-xml2 \
    r-yaml \
    giflib \
    cairo \
    pango \
    libjpeg-turbo \
    nodejs \
    altair \
    libiconv \
    nbstripout

# Install phantomjs via webshot for Doc/PDF with JS graphs in it
RUN ln -s /bin/tar /bin/gtar \
    && R -e "library(webshot); webshot::install_phantomjs()" \
    && mv /root/bin/phantomjs /usr/bin/phantomjs \
    && chmod a+rx /usr/bin/phantomjs

RUN npm config set unsafe-perm true \
    && npm install -g vega vega-lite

# We want all packages to use the default MRAN mirror so that when we upgrade users, they don't magically get new packages
# However, when they install their own packages, we want this to come from latest CRAN
# RUN echo "\nr-cran-repos=http://cran.rstudio.com" >> /etc/rstudio/rsession.conf  This one has no effect
RUN mv /usr/local/lib/R/etc/Rprofile.site /usr/local/lib/R/etc/Rprofile2.site \
    && grep -v options\(repos /usr/local/lib/R/etc/Rprofile2.site > /usr/local/lib/R/etc/Rprofile.site \
    && rm /usr/local/lib/R/etc/Rprofile2.site \
    && rm -rf /tmp/*

# Cant use Cran-mirror as it only supports 3.4.x
RUN echo "options(repos = c(CRAN=https://cran.rstudio.com), download.file.method = libcurl)" >> /usr/local/lib/R/etc/Rprofile.site \
    && git config --system credential.helper cache --timeout=3600 \
    && git config --system push.default simple \
    && update-alternatives --set editor /bin/nano

COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh
EXPOSE 8787
CMD ["/usr/local/bin/start.sh"]
