FROM rocker/verse:3.5.3@sha256:7cf4253239c338fbef924ddf46b7632cc52d1da7616e3d80b11bca0093071cb2
LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

ARG GITHUB_PAT
ARG NCPUS=1

# R version 3.5.3 is not available via Conda, sticking to 3.5.1
# ENV R_VERSION=${R_VERSION:-3.5.1}
ENV R_VERSION=3.5.1
ENV PY_VERSION=${PY_VERSION:-3.7}

ENV USER=rstudio
ENV LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8

ENV PATH /opt/conda/bin:$PATH

## Set locale & install packages
RUN echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen en_GB.utf8 \
  && update-locale LANG=en_GB.UTF-8 \
  && apt-get -qq update \
  && apt-get -qq install -y --no-install-recommends locales gnupg2 \
  && rm -rf /var/lib/apt/lists/*;


#RUN conda install
#
COPY files/apt_packages /tmp/
RUN apt-get -qq update \
    && apt-get -qq install -y \
    $(cat /tmp/apt_packages) \
    # Dependencies of rgl which itself is a dependency
    && rm -rf /var/lib/apt/lists/*; \
    # Install texlive with LaTex binaries and tools (scheme-basic)
    wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
    && mkdir /install-tl-unx; \
    tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1; \
      echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile; \
    /install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile; \
    rm -r /install-tl-unx; \
    rm install-tl-unx.tar.gz; \
#    # Install SimbaAthena ODBC drivers
    wget -q https://s3.amazonaws.com/athena-downloads/drivers/ODBC/SimbaAthenaODBC_1.0.3/Linux/simbaathena-1.0.3.1004-1.x86_64.rpm -P /tmp \
    && alien -i /tmp/simbaathena-1.0.3.1004-1.x86_64.rpm \
    && rm -f /tmp/simbaathena-1.0.3.1004-1.x86_64.rpm

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
  /bin/bash ~/miniconda.sh -b -p /opt/conda && \
  rm ~/miniconda.sh && \
  /opt/conda/bin/conda clean -tipsy && \
  ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
  echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
#
#
# Configure R
COPY files/.condarc /opt/conda/
RUN conda install python=$PY_VERSION r-base=$R_VERSION
RUN echo '.libPaths(c("~/R/library",paste0(R.home(), "/library"), .libPaths()))' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo "PATH=\"${PATH}\"" >> /usr/local/lib/R/etc/Renviron \
    && echo "AWS_DEFAULT_REGION=eu-west-1" >> /usr/local/lib/R/etc/Renviron \
    && echo "r-libs-user=~/R/library" >> /etc/rstudio/rsession.conf \
## Users want nano when they git commit not vim
## Users will use the reticulate package within R to run Python code.  This makes sure we always use py3
    && update-alternatives --set editor /bin/nano

#
#
# Install Conda Packages
COPY files/conda_packages /tmp/
RUN conda config --system --set pip_interop_enabled True \
    && conda install \
    $(cat /tmp/conda_packages) \
    && rm -f /tmp/{apt_packages,conda_packages}

RUN ln -s /bin/tar /bin/gtar \
#    # Install phantomjs via webshot for Doc/PDF with JS graphs in it
    && R -e "library(webshot); webshot::install_phantomjs()" \
    && mv /root/bin/phantomjs /usr/bin/phantomjs \
    && chmod a+rx /usr/bin/phantomjs

RUN npm config set unsafe-perm true \
    && npm install -g vega vega-lite

# We want all packages to use the default MRAN mirror so that when we upgrade users, they don't magically get new packages
# However, when they install their own packages, we want this to come from latest CRAN
# RUN echo "\nr-cran-repos=http://cran.rstudio.com" >> /etc/rstudio/rsession.conf  This one has no effect
RUN mv /usr/local/lib/R/etc/Rprofile.site /usr/local/lib/R/etc/Rprofile2.site
RUN grep -v options\(repos /usr/local/lib/R/etc/Rprofile2.site > /usr/local/lib/R/etc/Rprofile.site
RUN rm /usr/local/lib/R/etc/Rprofile2.site \
    && rm -rf /tmp/*

# Can't use Cran-mirror as it only supports 3.4.x
RUN echo "options(repos = c(CRAN='https://cran.rstudio.com'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
# Configure git
  && git config --system credential.helper 'cache --timeout=3600' \
  && git config --system push.default simple

# Adds Athena ODBC driver configuration
COPY files/odbc* /etc/


COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8787

CMD ["/usr/local/bin/start.sh"]
