FROM alpine:latest AS build
ARG TARGETARCH
ARG CLIENTVERSION
WORKDIR /opt/hide.me/
COPY files/fetch.sh /opt/hide.me/fetch.sh
RUN apk add --no-cache curl bash sed grep && \
    /bin/bash fetch.sh ${TARGETARCH} ${CLIENTVERSION}

FROM alpine:latest
ARG TARGETARCH
ARG BUILD_DATE

LABEL org.opencontainers.image.authors="Nita Vesa <nita.vesa@outlook.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="werecatf/hidemevpn"
LABEL org.label-schema.description="Hide.me VPN client"
LABEL org.label-schema.url="https://hide.me"
LABEL org.label-schema.docker.cmd="docker run -v ./etc:/opt/hide.me/etc --env-file ./env --cap-add SYS_MODULE --cap-add NET_ADMIN --sysctl net.ipv4.conf.all.src_valid_mark=1 --name hidemevpn -itd werecatf/hidemevpn:latest"
ENV APP_NAME="Hide.me VPN"
WORKDIR /opt/hide.me/
COPY --from=build /opt/hide.me/hide.me /opt/hide.me/
COPY --from=build /opt/hide.me/CA.pem /opt/hide.me/
RUN apk add --no-cache curl bash sed jq iputils-ping python3 py3-psutil xz

ENV S6_OVERLAY_VERSION="3.1.6.2"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    rm /tmp/s6-overlay-noarch.tar.xz
RUN case ${TARGETARCH} in \
    "amd64")  export arch="x86_64" ;; \
    "arm64")  export arch="aarch64" ;; \
    "riscv64") export arch="riscv64" ;; \
    "arm/v7") export arch="armhf" ;; \
    "arm/v6") export arch="armel" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -L -o /tmp/s6-overlay.tar.xz https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${arch}.tar.xz \
    && tar -C / -Jxpf /tmp/s6-overlay.tar.xz \
    && rm /tmp/s6-overlay.tar.xz

COPY files/healthcheck.sh /opt/hide.me/
COPY files/start.sh /opt/hide.me/
COPY files/prepareconfig.sh /opt/hide.me/
COPY files/intervalhandler.py /opt/hide.me/
RUN chmod a+x /opt/hide.me/healthcheck.sh
RUN chmod a+x /opt/hide.me/start.sh
RUN chmod a+x /opt/hide.me/prepareconfig.sh
RUN chmod a+x /opt/hide.me/intervalhandler.py
COPY s6-overlay/ /etc/s6-overlay/
HEALTHCHECK --interval=5m --timeout=30s --start-period=3m --start-interval=15s --retries=3 CMD /opt/hide.me/healthcheck.sh
ENTRYPOINT ["/init"]
CMD ["/opt/hide.me/start.sh"]
