FROM ubuntu:focal as builder

ARG ODYSSEY_VERSION

# Use instead of ENV.
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp/

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    lsb-release \
    ca-certificates \
    libssl-dev \
    gnupg \
    openssl \
    git

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    postgresql-server-dev-12


RUN git clone --branch ${ODYSSEY_VERSION} --depth 1 git://github.com/yandex/odyssey.git \
    && cd odyssey \
    && mkdir build \
    && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release .. \
    && make -j


FROM ubuntu:focal

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl1.1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/odyssey/build/sources/odyssey /usr/local/bin/

RUN groupadd -r odyssey && useradd -r -g odyssey odyssey && mkdir /etc/odyssey
COPY --from=builder /tmp/odyssey/odyssey.conf  /etc/odyssey/odyssey.conf.sample

USER odyssey
EXPOSE 5432

ENTRYPOINT ["/usr/local/bin/odyssey"]
CMD ["/etc/odyssey/odyssey.conf"]
