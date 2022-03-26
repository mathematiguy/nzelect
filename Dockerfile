FROM ubuntu:18.04

# Use New Zealand mirrors
RUN sed -i 's/archive/nz.archive/' /etc/apt/sources.list

RUN apt update

# Set timezone to Auckland
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y locales tzdata
RUN locale-gen en_NZ.UTF-8
RUN dpkg-reconfigure locales
RUN echo "Pacific/Auckland" > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
ENV LANG en_NZ.UTF-8
ENV LANGUAGE en_NZ:en

# Create user 'kaimahi' to create a home directory
RUN useradd kaimahi
RUN mkdir -p /home/kaimahi/
RUN chown -R kaimahi:kaimahi /home/kaimahi
ENV HOME /home/kaimahi

RUN apt update && apt install -y \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libmagick++-dev \
  cargo \
  libharfbuzz-dev \
  libfribidi-dev \
  desktop-file-utils \
  libudunits2-dev \
  gdal-bin \
  libzmq3-dev \
  wget

# install pandoc
RUN wget https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-1-amd64.deb -P /root
RUN dpkg -i /root/pandoc-2.5-1-amd64.deb

# Install R
RUN apt install -y r-base

RUN Rscript -e 'install.packages(c("tidyverse", "devtools", "drake", "bookdown", "kableExtra", "here", "reticulate", "furrr", "optparse"), repos = "https://cran.stat.auckland.ac.nz", Ncpus=parallel::detectCores()-1, dependencies=TRUE)'
RUN Rscript -e 'install.packages(c("devtools", "extrafont", "plyr"))'
RUN Rscript -e 'devtools::install_github("ellisp/nzelect/pkg1")'
