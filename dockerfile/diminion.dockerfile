FROM rocker/verse:4.0.0
LABEL maintainer="excel.que@gmail.com"
LABEL version="0.1"
LABEL description="Docker for holding requisite software for the Diminion Nextflow Pipeline"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
