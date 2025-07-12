# Stage 1: build
FROM ubuntu:22.04 AS build
WORKDIR /tmp
RUN apt-get update && apt-get install -y curl unzip xz-utils git libglu-dev
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
WORKDIR /usr/local/flutter
RUN git checkout 3.24.4
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter doctor -v

WORKDIR /app
COPY mytrainer2client/ ./
# fetch deps & generate locals
RUN flutter pub get
RUN flutter gen-l10n
# build web
RUN flutter build web --release

# Stage 2: serve
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
