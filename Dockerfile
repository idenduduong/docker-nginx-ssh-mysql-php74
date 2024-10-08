FROM ubuntu:22.04
MAINTAINER Agus Setya R <agussetyar@indoxploit.or.id>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Initialization socket directory
RUN mkdir /var/run/mysqld
RUN mkdir /var/run/php
RUN mkdir /var/run/sshd

# Let the conatiner know that there is no tty
ARG DEBIAN_FRONTEND noninteractive

# Argument for docker-compose
ARG SSH_USERNAME
ARG SSH_PASSWORD
ARG MYSQL_ROOT_PASSWORD

# Setup Environment
ENV TZ=Asia/Ho_Chi_Minh
ENV MYSQL_ROOT_PASSWORD $MYSQL_ROOT_PASSWORD

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt update && apt upgrade -y

#################################################################################

RUN apt-get install -y software-properties-common && apt-get install -y apt-transport-https

# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv BC19DDBA
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv 8DA84635

RUN add-apt-repository 'deb https://releases.galeracluster.com/mysql-wsrep-8.0/ubuntu jammy main'
RUN add-apt-repository 'deb https://releases.galeracluster.com/galera-4/ubuntu jammy main'

COPY galera.pref /etc/apt/preferences.d/galera.pref

USER root
RUN apt-get update -y

# RUN apt -y install galera-4 galera-arbitrator-4 mysql-wsrep-8.0 rsync lsof
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install galera-4 galera-arbitrator-4 mysql-wsrep-8.0 rsync lsof

#################################################################################

# Basic requirements
RUN apt install -y curl htop nano openssl sudo unzip vim wget
# RUN apt install -y openssh-server nginx php php-fpm mariadb-server mariadb-client supervisor
RUN apt install -y openssh-server supervisor

# PHP Requirements
# RUN apt install -y php-curl php-mysql php-mbstring php-xml php-gd

# Add system user
RUN useradd -G sudo -s /bin/bash -m -d /home/$SSH_USERNAME -p $(openssl passwd -1 "$SSH_PASSWORD") $SSH_USERNAME

# Nginx config
# RUN sed -i -e "s/keepalive_timeout 65;/keepalive_timeout 65;\n\tclient_max_body_size 100m;/" /etc/nginx/nginx.conf

# PHP-FPM config
# RUN sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 100M/" /etc/php/7.4/fpm/php.ini
# RUN sed -i -e "s/post_max_size = 8M/upload_max_filesize = 100M/" /etc/php/7.4/fpm/php.ini
# RUN sed -i -e "s/;daemonize = yes/daemonize = no/" /etc/php/7.4/fpm/php-fpm.conf
# RUN sed -i -e "s/;catch_workers_output = yes/catch_workers_output = yes/" /etc/php/7.4/fpm/pool.d/www.conf

# MySQL config
# RUN sed -i -e "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
# RUN chown mysql:mysql /var/run/mysqld

# Custom config
# ADD ./nginx-site.conf /etc/nginx/sites-available/default
ADD ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Initialization script
ADD ./start.sh /start.sh

# Application
# COPY app /usr/share/nginx/html

# Expose Ports
EXPOSE 22
EXPOSE 80
EXPOSE 3306

# Volumes
# VOLUME ["/var/lib/mysql", "/usr/share/nginx/html"]

# Run
CMD ["/bin/bash", "/start.sh"]