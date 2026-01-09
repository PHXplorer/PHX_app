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

RUN ["R", "-e", "renv::restore()"]

EXPOSE 3838

CMD bash
