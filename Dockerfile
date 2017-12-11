FROM debian:jessie
MAINTAINER not important

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes --no-install-recommends \
      apache2 \
      libapache2-mod-php5 \
      php5 \
      php5-cli \
      php5-gd \
      php5-mysql \
      php5-curl \
      php5-dev \
      php5-xdebug \
      mysql-server \
      mysql-client \
      curl \
      supervisor \
      ca-certificates \
      vim \
      less \
      php5-dev \
      libsqlite3-dev \
      sqlite3 \
      ruby \
      ruby-dev \
      phpmyadmin \
      git \
      sudo \
      make \
      g++ \
      php-pear \
      wget \
      graphviz

#
# Add blackfire
#
RUN wget -O - https://packagecloud.io/gpg.key | apt-key add -
RUN echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list
RUN apt-get update
RUN apt-get install blackfire-agent
RUN apt-get install blackfire-php


#
# Xdebug remote host setup
#
RUN echo "zend_extension=/usr/lib/php5/20131226/xdebug.so" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_host=10.0.23.1" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_port = 9000" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_enable = 1" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_autostart = 0" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.profiler_enable_trigger = 1" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.remote_handler = dbgp" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.profiler_enable=0" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.profiler_output_dir=/var/www/profiler" >> /etc/php5/apache2/conf.d/20-xdebug.ini \
    && echo "xdebug.profiler_output_name = "cachegrind.out.%p"" >> /etc/php5/apache2/conf.d/20-xdebug.ini
    

#
# Install MailCatcher
#
RUN gem install mailcatcher

#
#Install Mailcatcher dependencies
#
RUN gem install coffee-script
RUN gem install compass
RUN gem install minitest
RUN gem install rake
#RUN gem install rdoc
RUN gem install sass
RUN gem install selenium-webdriver
RUN gem install sprockets
RUN gem install sprockets-helpers
RUN gem install sprockets-sass
RUN gem install uglifier


#
# Setup MailCatcher Apache proxy-pass
# This should be obsolete now - keeping it for the record only.
#RUN sed -i -e '/<\/VirtualHost>/i \ProxyPass \/mailcatcher http:\/\/127.0.0.1:1080\/ \n' /etc/apache2/sites-enabled/000-default.conf
#RUN sed -i -e '/<\/VirtualHost>/i \ProxyPass \/assets\/mailcatcher.css http:\/\/127.0.0.1:1080\/assets\/mailcatcher.css \n' /etc/apache2/sites-enabled/000-default.conf
#RUN sed -i -e '/<\/VirtualHost>/i \ProxyPass \/assets\/mailcatcher.js http:\/\/127.0.0.1:1080\/assets\/mailcatcher.js \n' /etc/apache2/sites-enabled/000-default.conf
RUN echo "sendmail_path = /usr/bin/env $(which catchmail)" | sudo tee /etc/php5/mods-available/mailcatcher.ini
RUN sudo php5enmod mailcatcher
RUN sudo service apache2 restart

#
# `mysqld_safe` patch
# @see https://github.com/wckr/wocker/pull/28#issuecomment-195945765
#
RUN sed -i -e 's/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1" ;;/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1 \& wait" ;;/' /usr/bin/mysqld_safe

#
# Apache Settings
# Enable required modules for rewrite, vhosts, and proxy (proxy required for mailcatcher)
#
RUN adduser --uid 1000 --gecos '' --disabled-password wocker \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && sed -i -e '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && sed -i -e "s#DocumentRoot.*#DocumentRoot \/var\/www\/wordpress#" /etc/apache2/sites-enabled/000-default.conf \
    && sed -i -e "s/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=wocker/" /etc/apache2/envvars \
    && sed -i -e "s/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=wocker/" /etc/apache2/envvars \
    && a2enmod rewrite \
    && a2enmod vhost_alias \
    && a2enmod ssl
#    && a2enmod proxy \
#    && a2enmod proxy_http
#   obsolete and not needed modules - see mailcatcher above.    

#
# php.ini settings
# Change sendmail path to allow the usage of mailcatcher 
#
RUN sed -i -e "s/^upload_max_filesize.*/upload_max_filesize = 256M/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^post_max_size.*/post_max_size = 267M/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^display_errors.*/display_errors = On/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^;mbstring.internal_encoding.*/mbstring.internal_encoding = UTF-8/" /etc/php5/apache2/php.ini \
    && sed -i -e "s/^;sendmail_path.*/sendmail_path = \/usr\/local\/bin\/phpsendmail/" /etc/php5/apache2/php.ini
#
# phpmyadmin copy config to sites-enabled
#
RUN cp /etc/phpmyadmin/apache.conf /etc/apache2/sites-enabled/

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar \
    && chmod +x wp-cli-nightly.phar \
    && mv wp-cli-nightly.phar /usr/local/bin/wp

#
# MySQL settings & Install WordPress
#
RUN mkdir -p /var/www/wordpress
RUN mkdir -p /var/www/profiler
ADD wp-cli.yml /var/www
WORKDIR /var/www/wordpress
RUN sed -i -e "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf \
    && find /var/lib/mysql -type f -exec touch {} \; && service mysql start \
    && mysqladmin -u root password root \
    && mysql -uroot -proot -e \
      "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@'%' identified by 'wordpress';" \
    && wp core download --allow-root \
    && wp core config --allow-root \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=localhost \
    && wp core install --allow-root \
      --admin_name=admin \
      --admin_password=admin \
      --admin_email=admin@debugger.dev \
      --url=http://debugger.dev \
      --title=WordPress \
    && wp theme update --allow-root --all \
    && wp plugin update --allow-root --all \
    && wp menu create "Navigation" --allow-root \
    && wp menu item add-custom navigation "Management Interface" "http://debugger.dev/interface.php" --allow-root \
    && wp menu item add-custom navigation "MailCatcher" "http://debugger.dev:1080" --allow-root \
    && wp menu item add-custom navigation "E-mail Log" "http://debugger.dev/sent-mail.htm" --allow-root \
    && wp menu item add-custom navigation "PhpMyAdmin" "http://debugger.dev/phpmyadmin/" --allow-root \
    && wp menu item add-custom navigation "WebGrind" "http://debugger.dev/webgrind/" --allow-root \
    && wp menu item add-custom navigation "PHP Info" "http://debugger.dev/info.php" --allow-root \
    && wp menu location assign Navigation top --allow-root
    
    
#Own directories and change permissions - this helps for the automatic scripts for Vhost creation
RUN chown -R wocker:wocker /var/www/wordpress
RUN chown -R wocker:wocker /var/www
RUN chown -R wocker:wocker /etc/apache2/sites-enabled
RUN chown -R wocker:wocker /etc/hosts
RUN chown -R wocker:wocker /var/www/profiler
RUN chmod 777 /etc/hosts
RUN touch /etc/hosts2
RUN chown -R wocker:wocker /etc/hosts2
RUN chmod 777 /etc/hosts2
RUN touch /etc/hosts3
RUN chown -R wocker:wocker /etc/hosts3
RUN chmod 777 /etc/hosts3
RUN git clone https://github.com/jokkedk/webgrind.git
RUN git clone https://github.com/interconnectit/Search-Replace-DB.git
#Add allowed command to the user Wocker, so that he can reload apache configuration without password via sudo
RUN echo "Cmnd_Alias      RESTART_APACHE = /usr/sbin/service apache2 force-reload" >> /etc/sudoers
RUN echo "Cmnd_Alias      UPDATE_HOSTS = /bin/cp -f /etc/hosts2 /etc/hosts"  >> /etc/sudoers
RUN echo "wocker ALL=NOPASSWD: RESTART_APACHE, UPDATE_HOSTS, /usr/local/bin/alias_vhost, /usr/local/bin/vhost, /usr/local/bin/wp-install, /bin/echo, /bin/sed" >> /etc/sudoers
ADD phpsendmail /usr/local/bin/phpsendmail
RUN chmod +x /usr/local/bin/phpsendmail
#
# Open ports
#
EXPOSE 80 443 3306 1080 9000

#
# Supervisor
#
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD restore_hosts /usr/local/bin/restore_hosts
ADD vhost /usr/local/bin/vhost
ADD alias_vhost /usr/local/bin/alias_vhost
ADD wp-install /usr/local/bin/wp-install
#Add Web interface and backend for adding WordPress installs + Vhosts
ADD interface.php /var/www/wordpress/interface.php
ADD info.php /var/www/wordpress/info.php
ADD placeholder.png /var/www/wordpress/placeholder.png
RUN chmod +x /usr/local/bin/vhost
RUN chmod +x /usr/local/bin/alias_vhost
RUN chmod +x /usr/local/bin/wp-install
RUN chmod +x /usr/local/bin/restore_hosts
RUN chmod 777 /var/lib/phpmyadmin/tmp/

#Install composer - everybody needs that
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

RUN find /var/lib/mysql -type f -exec touch {} \;
CMD ["/usr/bin/supervisord"]
