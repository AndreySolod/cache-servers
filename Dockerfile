FROM ubuntu:23.04
MAINTAINER "SoloAD2010@yandex.ru"

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y apt-cacher-ng supervisor

RUN sed -i "s|# ForeGround: 0|ForeGround: 1|" /etc/apt-cacher-ng/acng.conf
VOLUME ["/var/cache/apt-cacher-ng"]

#supervisor configuration
RUN mkdir -p /var/log/supervisor/
RUN sed -i "s|^logfile=.*|logfile=/var/log/supervisor/supervisord.log ;|" /etc/supervisor/supervisord.conf
RUN cat > /etc/supervisor/conf.d/apt-cacher-ng.conf <<EOF
[program:apt-cacher-ng]
priority=10
directory=/etc/apt-cacher-ng/
command=/usr/sbin/apt-cacher-ng -c /etc/apt-cacher-ng/
user=root
autostart=true
autorestart=true
stopsignal=QUIT
stdout_logfile=/var/log/supervisor/%(program_name)s.log
stderr_logfile=/var/log/supervisor/%(program_name)s.log
EOF

EXPOSE 3142

## python-server

RUN apt-get install -y python3 python3-pip python-is-python3 libffi-dev
RUN pip install devpi-server devpi-web --break-system-packages
EXPOSE 3143
VOLUME /root/.devpi

## Ruby-server
RUN apt-get install -y ruby rubygems
RUN gem install geminabox
RUN mkdir /geminabox && cd /geminabox && mkdir data
RUN cat > /geminabox/config.ru <<EOF
require "rubygems"
require "geminabox"

Geminabox.rubygems_proxy = true
Geminabox.data = "./data"
Geminabox.allow_remote_failure = true

run Geminabox::Server
EOF

RUN cat > /etc/supervisor/conf.d/geminabox.conf <<EOF
[program:geminabox]
priority=10
directory=/geminabox
command=rackup
user=root
autostart=true
autorestart=true
stopsignal=QUIT
stdout_logfile=/var/log/supervisor/%(program_name)s.log
stderr_logfile=/var/log/supervisor/%(program_name)s.log
EOF

VOLUME /geminabox/data
EXPOSE 9292

COPY ./entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
