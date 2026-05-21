# Use latest alpine base image
FROM alpine:latest

# Install curl
RUN apk add --no-cache curl bash tzdata bind-tools jq

ARG VERSION=dev
ARG BUILD_DATE=unknown

# Set version label
LABEL build_version="Porkbun-DNS-Updater, Version: ${VERSION}, Build-date: ${BUILD_DATE}"
LABEL maintainer=dmleet

# Copy convert shell scripts to /opt
COPY porkbun_dns_updater /opt/

# Set scripts as executable
RUN chmod +rxxx /opt/porkbun_dns_updater

# Set default docker variables
ENV DOMAIN=${DOMAIN:-NULL}
ENV SUB_DOMAINS=${SUB_DOMAINS:-@}
ENV API_KEY=${API_KEY:-NULL}
ENV API_SECRET=${API_SECRET:-NULL}
ENV INTERVAL=${INTERVAL:-600}

CMD ["/opt/porkbun_dns_updater"]