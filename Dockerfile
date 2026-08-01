# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder

ARG VERSION=v1.9.1

ENV VIRTUAL_ENV=/opt/venv

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        cargo \
        libffi-dev \
        libssl-dev \
    && python -m venv "$VIRTUAL_ENV" \
    && "$VIRTUAL_ENV/bin/pip" install --upgrade pip setuptools wheel \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --branch ${VERSION} --depth 1 \
    https://github.com/Flowseal/tg-ws-proxy.git .

RUN "$VIRTUAL_ENV/bin/pip" install cryptography==46.0.5


FROM python:3.12-slim

ENV PATH=/opt/venv/bin:$PATH \
    TG_WS_PROXY_HOST=0.0.0.0 \
    TG_WS_PROXY_PORT=1443 \
    TG_WS_PROXY_SECRET="" \
    TG_WS_PROXY_DC_IPS="2:149.154.167.220 4:149.154.167.220" \
    TG_WS_PROXY_CF_WORKER=""

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        tini \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system app \
    && useradd --system --gid app --create-home app

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /src/proxy ./proxy

USER app

EXPOSE 1443/tcp

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["/bin/sh", "-lc", "\
exec python -u proxy/tg_ws_proxy.py \
--host ${TG_WS_PROXY_HOST} \
--port ${TG_WS_PROXY_PORT} \
"]
