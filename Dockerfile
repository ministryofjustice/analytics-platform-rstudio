FROM rocker/verse:3.4.2@sha256:f82e4b3a2c5410f338c7c199de0557ea75ca537e51220e8925747d75989377cd

LABEL maintainer=analytics-platform-tech@digital.justice.gov.uk

ENV R_VERSION=${R_VERSION:-3.4.2}
ENV USER=rstudio

# Add bytemark apt mirrors
RUN printf '\ndeb http://mirror.bytemark.co.uk/debian stretch main\ndeb-src http://mirror.bytemark.co.uk/debian stretch main' \
    >> /etc/apt/sources.list.d/bytemark.list

# Set locale
RUN apt-get -qq update \
    && apt-get -qq install -y --no-install-recommends locales; \
    echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_GB.utf8 \
    && /usr/sbin/update-locale LANG=en_GB.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_GB.UTF-8 \
    LANG=en_GB.UTF-8

# Configure R
RUN echo '\n.libPaths("~/R/library")' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo "PATH=\"${PATH}\"" >> /usr/local/lib/R/etc/Renviron \
    && echo "r-libs-user=~/R/library" >> /etc/rstudio/rsession.conf

# Add static list of apt & R packages
COPY files/*_packages /tmp/

# Install (R Packages) dependencies
RUN apt-get -qq update && apt-get -qq install -y \
    $(cat /tmp/apt_packages) \
    # Dependencies of rgl which itself is a dependency
    mesa-common-dev \
    libglu1-mesa-dev; \
    rm -rf /var/lib/apt/lists/*; \
    # Install texlive with LaTex binaries and tools (scheme-basic)
    wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz \
	&& mkdir /install-tl-unx; \
	tar -xvf install-tl-unx.tar.gz -C /install-tl-unx --strip-components=1; \
    echo "selected_scheme scheme-basic" >> /install-tl-unx/texlive.profile; \
	/install-tl-unx/install-tl -profile /install-tl-unx/texlive.profile; \
    rm -r /install-tl-unx; \
	rm install-tl-unx.tar.gz; \
	# Install SimbaAthena ODBC drivers
	wget -q https://s3.amazonaws.com/athena-downloads/drivers/ODBC/SimbaAthenaODBC_1.0.3/Linux/simbaathena-1.0.3.1004-1.x86_64.rpm -P /tmp \
	&& alien -i /tmp/simbaathena-1.0.3.1004-1.x86_64.rpm \
	&& rm -f /tmp/simbaathena-1.0.3.1004-1.x86_64.rpm

# Need vega and vega lite npm packages to render high res vega charts
RUN sudo curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash \
    && apt-get install -y nodejs npm

# The Altair python allows us to use this in R via the reticulate package
RUN npm config set unsafe-perm true \
    && npm install -g vega vega-lite \
    && pip install altair

# This allows users to interact with AWS using boto3 via reticulate
RUN pip install boto3

# Install etl_manager to allow analysts declare databases on athena via R (using reticulate)
RUN pip install git+git://github.com/moj-analytical-services/etl_manager.git@v1.0.2#egg=etl_manager

# Install R Packages
RUN R -e "source('https://bioconductor.org/biocLite.R')" \
    && install2.r --error \
    --deps TRUE $(cat /tmp/R_packages) \
    && rm -f /tmp/{apt_packages,R_packages}

# Install R S3 package
RUN install2.r --error \
    --deps TRUE --repos 'http://cloudyr.github.io/drat' \
    'aws.signature' \
    'aws.s3' \
    'aws.ec2metadata' \
    # Install MOJ S3tools package
    && R -e "devtools::install_github('moj-analytical-services/s3tools')" \
    && R -e "devtools::install_github('moj-analytical-services/s3browser')" \
    # Install webshot (dependency => PhantomJS) for Doc/PDF with JS graphs in it
    && R -e "install.packages('webshot')" \
    && R -e "webshot::install_phantomjs()" \
    && mv /root/bin/phantomjs /usr/bin/phantomjs \
    && chmod a+rx /usr/bin/phantomjs

# Configure git
RUN git config --system credential.helper 'cache --timeout=3600' \
    && git config --system push.default simple

# Adds Athena ODBC driver configuration
COPY files/odbc* /etc/

COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8787

CMD ["/usr/local/bin/start.sh"]
