FROM rocker/r-ver:4.4.0

RUN apt-get update && apt-get install -y --no-install-recommends \
  libcurl4-openssl-dev \
  pkg-config \
  unixodbc-dev \
  libxml2-dev \
  zlib1g-dev \
  libpng-dev \
  libgit2-dev

WORKDIR /application
COPY . .

RUN Rscript -e "Sys.setenv(RENV_CONFIG_PAK_ENABLED='FALSE')" -e "options(renv.config.pak.enabled=FALSE)" -e "print(Sys.getenv('RENV_CONFIG_PAK_ENABLED'))" -e "print(getOptions('renv.config.pak.enabled'))" -e "renv::restore(prompt=FALSE)"

EXPOSE 3838

CMD bash
