# Stage 1: Build
FROM alpine:latest AS builder

RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    libuv-dev \
    openssl-dev \
    hwloc-dev \
    linux-headers

WORKDIR /src

RUN git clone https://github.com/xmrig/xmrig.git . \
    && git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

# Set donation level to 0% in source
RUN sed -i 's/kDefaultDonateLevel = 1;/kDefaultDonateLevel = 0;/g' src/donate.h \
    && sed -i 's/kMinimumDonateLevel = 1;/kMinimumDonateLevel = 0;/g' src/donate.h

WORKDIR /src/build

# Compile with maximum optimization for current CPU architecture
RUN cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS="-O3 -march=native" \
    -DCMAKE_CXX_FLAGS="-O3 -march=native" \
    -DWITH_HWLOC=ON \
    -DWITH_HTTPD=OFF \
    -DWITH_TLS=ON \
    && make -j$(nproc)

# Stage 2: Minimal Runtime
FROM alpine:latest

RUN apk add --no-cache \
    libuv \
    openssl \
    hwloc

WORKDIR /xmrig

COPY --from=builder /src/build/xmrig /usr/local/bin/xmrig

ENTRYPOINT ["xmrig"]
