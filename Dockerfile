FROM registry.service.dsd.io/opguk/nginx:0.1.78

RUN  apt-get -y update
RUN  apt-get -y install ruby2.0 ruby2.0-dev nodejs
RUN  gem2.0 install bundle dashing

ADD Gemfile /app/
ADD Gemfile.lock /app/
WORKDIR /app
RUN  bundle

ADD  docker/confd /etc/confd
ADD  docker/service /etc/service
RUN  chmod a+x /etc/service/dashing/run

ADD  docker/my_init.d /etc/my_init.d
RUN  chmod a+x /etc/my_init.d/*

ADD  . /app
RUN  chown -R app:app /app


ENV  OPG_SERVICE data-dashboard

EXPOSE 80
EXPOSE 443
