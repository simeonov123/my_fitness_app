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

ARG APP_TITLE=MVFitness
ARG API_BASE_URL=https://mvfitness.vinkel.org/api
ARG KEYCLOAK_REALM_URL=https://mvfitness.auth.vinkel.org/realms/myrealm
ARG KEYCLOAK_LOGOUT_URL=https://mvfitness.auth.vinkel.org/realms/myrealm/protocol/openid-connect/logout
ARG OIDC_CLIENT_ID=mytrainer2client
ARG MOBILE_REDIRECT_URI=com.mvfitness.mytrainer2client://oauthredirect
ARG MOBILE_POST_LOGOUT_REDIRECT_URI=com.mvfitness.mytrainer2client://logoutredirect
ARG ALLOW_INSECURE_AUTH=false

# build web
RUN flutter build web --release \
  --dart-define=APP_TITLE=${APP_TITLE} \
  --dart-define=API_BASE_URL=${API_BASE_URL} \
  --dart-define=KEYCLOAK_REALM_URL=${KEYCLOAK_REALM_URL} \
  --dart-define=KEYCLOAK_LOGOUT_URL=${KEYCLOAK_LOGOUT_URL} \
  --dart-define=OIDC_CLIENT_ID=${OIDC_CLIENT_ID} \
  --dart-define=MOBILE_REDIRECT_URI=${MOBILE_REDIRECT_URI} \
  --dart-define=MOBILE_POST_LOGOUT_REDIRECT_URI=${MOBILE_POST_LOGOUT_REDIRECT_URI} \
  --dart-define=ALLOW_INSECURE_AUTH=${ALLOW_INSECURE_AUTH}

# Stage 2: serve
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
