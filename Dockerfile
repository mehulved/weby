FROM ruby:2.5.7 as development

LABEL org.opencontainers.image.authors="mehul.n.ved@gmail.com"
LABEL com.weby.version=3.0

RUN apt-get update
RUN apt-get install -y git imagemagick libpq-dev libncurses5-dev libffi-dev curl build-essential libssl-dev libreadline6-dev zlib1g-dev zlib1g libsqlite3-dev libmagickwand-dev libqtwebkit-dev libqt4-dev libreadline-dev libxslt-dev

RUN useradd -ms /bin/bash weby
USER weby
WORKDIR /weby
COPY --chown=weby . /weby
COPY --chown=weby ./config/database.yml.example /weby/config/database.yml
COPY --chown=weby ./config/secrets.yml.example /weby/config/secrets.yml

RUN gem install bundler
RUN bundle install

ENV RAILS_ENV=development
ENV WEBY_HOSTNAME="0.0.0.0"

EXPOSE 3000

CMD ["./entrypoint.sh"]


FROM development as production

ENV RAILS_ENV=production
