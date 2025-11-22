ARG TARGETARCH=linux/amd64

FROM --platform=$TARGETARCH public.ecr.aws/lambda/provided:al2023 AS vips_builder

ENV VIPS_VERSION=8.17.3

RUN dnf update --refresh
RUN dnf install -y --setopt=tsflags=nodocs \
    autoconf automake pkgconfig libtool meson ninja-build \
    glib2-devel libwebp-devel libpng-devel libjpeg-turbo-devel orc-devel \
    gcc gcc-c++ make \
    cmake expat-devel

WORKDIR /usr/local/src
RUN curl -fsSL https://github.com/libvips/libvips/archive/refs/tags/v${VIPS_VERSION}.tar.gz -o vips-${VIPS_VERSION}.tar.gz
RUN tar xzf vips-${VIPS_VERSION}.tar.gz
WORKDIR /usr/local/src/libvips-${VIPS_VERSION}
RUN meson setup build --prefix=/usr
RUN ninja -C build install

FROM --platform=$TARGETARCH public.ecr.aws/lambda/provided:al2023 AS app_builder

ENV GO_VERSION=1.25.4
ENV GOROOT=/usr/local/go
ENV PATH=$GOROOT/bin:$PATH

RUN dnf install -y gcc tar
RUN curl -fsSL -H "Accept-Encoding:" https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xz

COPY --from=vips_builder /usr/lib64 /usr/lib64
COPY --from=vips_builder /usr/include /usr/include
ENV PKG_CONFIG_PATH=/usr/lib64/pkgconfig

WORKDIR /app
COPY . .
RUN go mod download
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=1 go build -tags lambda.norpc -o bootstrap ./animeclassifier

FROM --platform=$TARGETARCH public.ecr.aws/lambda/provided:al2023

RUN dnf install -y \
    glib2 libpng libjpeg-turbo libtiff lcms2 libexif orc expat

WORKDIR ${LAMBDA_TASK_ROOT}

COPY --from=app_builder /app/bootstrap /var/runtime/
COPY --from=vips_builder /usr/lib64/libvips* /usr/lib64/
COPY --from=vips_builder /usr/lib64/libgobject-2.0.so* /usr/lib64/
COPY --from=vips_builder /usr/lib64/libglib-2.0.so* /usr/lib64/

CMD ["bootstrap"]
