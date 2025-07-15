FROM ruby:3.2.8-alpine

ENV APP_ROOT_PATH /var/app
ENV BUNDLE_VERSION 2.3.3
ENV BUNDLE_PATH /usr/local/bundle/gems
ENV TMP_PATH /tmp/
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_PORT 3000

RUN apk add --update \
      binutils-gold \
      build-base \
      curl \
      file \
      g++ \
      gcc \
      git \
      less \
      libstdc++ \
      libffi-dev \
      libc-dev \
      linux-headers \
      libxml2-dev \
      libxslt-dev \
      libgcrypt-dev \
      yaml-dev \
      make \
      netcat-openbsd \
      nodejs \
      openssl \
      pkgconfig \
      postgresql-dev \
      python3 \
      tzdata \
      freetype \
      ttf-dejavu ttf-freefont \
      imagemagick \
      yarn

RUN rm -rf /var/cache/apk/*
RUN mkdir -p $APP_ROOT_PATH

COPY --from=madnight/alpine-wkhtmltopdf-builder:0.12.5-alpine3.10-606718795 \
    /bin/wkhtmltopdf /usr/bin/wkhtmltopdf

RUN gem install bundler --version "$BUNDLE_VERSION" \
    && rm -rf $GEM_HOME/cache/*

WORKDIR $APP_ROOT_PATH
EXPOSE $RAILS_PORT

COPY Gemfile Gemfile.lock ./
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install

ENTRYPOINT [ "bundle", "exec" ]