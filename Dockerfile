# Pinned base image (Dependabot keeps this current)
FROM alpine:3.22

# Install runtime dependencies
RUN apk add --no-cache bash curl jq tzdata

ARG VERSION=dev
ARG BUILD_DATE=unknown

# Set version labels
LABEL build_version="Porkbun-DNS-Updater, Version: ${VERSION}, Build-date: ${BUILD_DATE}"
LABEL maintainer=dmleet
LABEL org.opencontainers.image.title="porkbun-dns-updater" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.source="https://github.com/dmleet/porkbun-dns-updater"

ENV APP_VERSION=${VERSION}

# Copy script to /opt as executable
COPY --chmod=0755 porkbun_dns_updater /opt/porkbun_dns_updater

# Run unprivileged; the script only needs network access and /tmp
USER nobody

# Healthy while a sync cycle has succeeded within the last few intervals
HEALTHCHECK --interval=60s --timeout=10s --start-period=120s \
    CMD ["/opt/porkbun_dns_updater", "--healthcheck"]

CMD ["/opt/porkbun_dns_updater"]
