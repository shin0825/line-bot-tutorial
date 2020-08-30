#Node.js & Yarn
FROM node:13.12-alpine as node

RUN apk add --no-cache bash curl && \
  curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.22.4


#Ruby & Bundler & postgresql-client
FROM ruby:2.7.1-alpine

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /opt/yarn-* /opt/yarn
RUN ln -fs /opt/yarn/bin/yarn /usr/local/bin/yarn
RUN apk add --no-cache git build-base libxml2-dev libxslt-dev postgresql-dev postgresql-client tzdata bash less && \
  cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

ENV APP_ROOT /app
RUN mkdir $APP_ROOT
WORKDIR $APP_ROOT

ENV LANG=ja_JP.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3 \
  BUNDLE_PATH=vendor/bundle \
  BUNDLE_APP_CONFIG=$APP_ROOT/.bundle
RUN gem update --system && \
  gem install --no-document bundler:2.1.4
