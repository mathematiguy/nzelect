FROM rocker/tidyverse:4.0

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

# Install R package requirements
RUN apt update
RUN apt install -y software-properties-common wget libgdal-dev libudunits2-dev libzmq3-dev imagemagick libharfbuzz-dev libfribidi-dev libmagick++-dev default-jre default-jdk
RUN R CMD javareconf

# install pandoc
RUN wget https://github.com/jgm/pandoc/releases/download/2.5/pandoc-2.5-1-amd64.deb -P /root
RUN dpkg -i /root/pandoc-2.5-1-amd64.deb

# Install R packages
RUN Rscript -e 'install.packages(c("devtools", "drake", "bookdown", "kableExtra", "here", "reticulate", "furrr", "optparse", "xlsx", "rgdal", "scales", "httr", "rvest", "testthat", "GGally", "gridExtra", "maps", "ggmap", "stringdist", "proj4", "devtools", "extrafont", "plyr", "unglue", "rJava"), repos = "https://cran.stat.auckland.ac.nz", Ncpus=parallel::detectCores()-1, dependencies=TRUE)'
RUN Rscript -e 'devtools::install_github("ellisp/nzelect/pkg1")'
