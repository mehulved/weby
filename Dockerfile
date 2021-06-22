FROM ruby:2.5.7 as development

LABEL org.opencontainers.image.authors="mehul.n.ved@gmail.com"
LABEL com.weby.version=1.0

RUN apt-get update
RUN apt-get install -y git imagemagick libpq-dev libncurses5-dev libffi-dev curl build-essential libssl-dev libreadline6-dev zlib1g-dev zlib1g libsqlite3-dev libmagickwand-dev libqtwebkit-dev libqt4-dev libreadline-dev libxslt-dev

COPY . /weby
WORKDIR /weby
COPY ./config/database.yml.example /weby/config/database.yml
COPY ./config/secrets.yml.example /weby/config/secrets.yml

RUN gem install bundler
RUN bundle install

ENV RAILS_ENV=development
ENV WEBY_HOSTNAME="0.0.0.0"

CMD ["./entrypoint.sh"]


FROM development as production

ENV RAILS_ENV=production
