FROM node:16.20.2-slim as node

FROM etriasnl/php-fpm:8.1.27-5 AS php

RUN ln -srf /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

ENV COMPOSER_HOME=/app/var/composer

RUN apt-get update && apt-get install -y --no-install-recommends --fix-missing \
    dnsutils iputils-ping lsof net-tools \
    git vim nano curl wget jq bash-completion unzip \
    s3cmd yamllint shellcheck \
    clamdscan \
    ffmpeg \
    libpng-dev \
    libdbi-perl libdbd-mysql-perl && \
    rm -rf /var/lib/apt/lists/*

RUN install-php-extensions xdebug

RUN chmod 0666 /var/log/newrelic/newrelic-daemon.log

RUN curl -sSfL 'https://raw.githubusercontent.com/dotenv-linter/dotenv-linter/master/install.sh' | sh -s -- -b /usr/bin

COPY --from=node /usr/local/bin/node /usr/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/lib/node_modules
COPY --from=node /opt/yarn* /opt/yarn

RUN ln -s /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm && \
    ln -s /usr/lib/node_modules/npm/bin/npx-cli.js /usr/bin/npx && \
    ln -s /opt/yarn/bin/yarn.js /usr/bin/yarn && \
    yarn config set cache-folder /app/var/yarn-cache && \
    chmod 777 /usr/local/share/.yarnrc && ln -s /usr/local/share/.yarnrc /.yarnrc

COPY docker/php-dev.ini /usr/local/etc/php/conf.d/

RUN nats --completion-script-bash > /etc/bash_completion.d/nats
RUN composer completion bash > /etc/bash_completion.d/composer

COPY docker/dev.bashrc /usr/local/etc/
RUN echo '. /usr/local/etc/dev.bashrc' >> /etc/bash.bashrc

WORKDIR /usr/local/etc/tools

COPY composer.* .
RUN --mount=type=cache,target=/app/var/composer \
    composer install --prefer-dist --no-progress --optimize-autoloader
ENV PATH="${PATH}:/usr/local/etc/tools/vendor/bin"
RUN ln -sfn psalm.phar vendor/bin/psalm

WORKDIR /app
