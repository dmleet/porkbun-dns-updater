# Use latest alpine base image
FROM alpine:latest

# Install curl
RUN apk add --no-cache curl bash tzdata bind-tools jq

# Set version label
LABEL build_version="Porkbun-DNS-Updater, Version: 1.0.1, Build-date: 2024-Nov-16"
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

CMD /opt/porkbun_dns_updater ${DOMAIN} ${SUB_DOMAINS} ${API_KEY} ${API_SECRET} ${INTERVAL}