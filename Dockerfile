FROM alpine AS kata-builder

ARG TARGETARCH

RUN apk add --no-cache curl jq tar zstd; \
    case "${TARGETARCH}" in \
        amd64|arm64|s390x|ppc64le) ;; \
        *) \
            echo "unsupported architecture: ${TARGETARCH}" >&2; \
            exit 1 \
            ;; \
    esac; \
    VERSION="$(curl -fsSL https://api.github.com/repos/kata-containers/kata-containers/releases/latest | jq -r '.tag_name')"; \
    curl -fsSL -o /tmp/kata-static.tar.zst \
        "https://github.com/kata-containers/kata-containers/releases/download/${VERSION}/kata-static-${VERSION}-${TARGETARCH}.tar.zst"; \
    mkdir /kata; \
    zstd -d -c /tmp/kata-static.tar.zst | tar -xvf - -C /kata; \
    rm -f /tmp/kata-static.tar.zst

FROM docker:dind

ARG USER_ID="1000"
ARG GROUP_ID="1000"
ARG USER_NAME="user"

RUN addgroup -g ${GROUP_ID} -S ${USER_NAME} && \
    adduser -u ${USER_ID} -G ${USER_NAME} -D ${USER_NAME} && \
    addgroup ${USER_NAME} docker

VOLUME /home/${USER_NAME}

COPY daemon.json /etc/docker/daemon.json
COPY --from=kata-builder /kata/ /