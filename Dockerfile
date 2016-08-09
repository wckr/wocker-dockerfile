FROM debian:jessie
MAINTAINER ixkaito <ixkaito@gmail.com>

ENV TERM "xterm"

ENV BUILDPCKGS "autoconf automake autopoint autotools-dev binutils bsdmainutils \
  build-essential bzip2 cpp cpp-4.9 debhelper dh-php5 dpkg-dev fakeroot file \
  g++ g++-4.9 gcc gcc-4.9 gettext gettext-base groff-base intltool-debian \
  libalgorithm-diff-perl libalgorithm-diff-xs-perl libalgorithm-merge-perl \
  libasan1 libasprintf-dev libasprintf0c2 libatomic1 libc-dev-bin libc6-dev \
  libcilkrts5 libcloog-isl4 libcroco3 libdpkg-perl libfakeroot \
  libfile-fcntllock-perl libgcc-4.9-dev libgettextpo-dev libgettextpo0 \
  libglib2.0-0 libglib2.0-data libgomp1 libisl10 libitm1 liblsan0 \
  libltdl-dev libltdl7 libmail-sendmail-perl libmpc3 libmpfr4 libpcre3-dev \
  libpcrecpp0 libpipeline1 libquadmath0 libsigsegv2 libssl-dev libssl-doc \
  libstdc++-4.9-dev libsys-hostname-long-perl libtimedate-perl libtool \
  libtsan0 libubsan0 libunistring0 linux-libc-dev m4 make man-db manpages \
  manpages-dev patch php-pear php5-dev pkg-php-tools po-debconf \
  shared-mime-info shtool xdg-user-dirs xz-utils zlib1g-dev"

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get clean \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    apache2 \
    ca-certificates \
    curl \
    less \
    libapache2-mod-php5 \
    lsb-release \
    mysql-server \
    mysql-client \
    nano \
    php5 \
    php5-cli \
    php5-curl \
    php5-dev \
    php5-gd \
    php5-mysql \
    php5-xdebug \
    supervisor \
    vim \
  && touch /etc/php5/cli/conf.d/30-xdebug.ini \
  && echo " \
    zend_extension=/usr/lib/php5/20131226/xdebug.so \
    xdebug.overload_var_dump = 1 \
    xdebug.var_disply_max_depth = -1 \
    xdebug.var_display_max_children = -1 \
    xdebug.var_display_max_data = 512 \
    xdebug.max_nesting_level = -1 \
    xdebug.collect_params = 4 \
    xdebug.profiler_enable_trigger = 1 \
    xdebug.profiler_enable = 0 \
    xdebug.remote_enable = 1 \
    xdebug.profiler_output_dir = \"/tmp\" \
    xdebug.profiler_output_name = \"cachegrind.out.%t-%s\"" \
      > /etc/php5/cli/conf.d/30-xdebug.ini \
  && apt-get remove ${BUILDPCKGS} \
  && rm -rf \
    /var/lib/apt/lists/* \
    /usr/share/man \
    /usr/games \
    /tmp/* \
    /var/tmp/*

#
# `mysqld_safe` patch
# @see https://github.com/wckr/wocker/pull/28#issuecomment-195945765
#
RUN sed -i -e \
  's/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1" ;;/file) cmd="$cmd >> "`shell_quote_string "$err_log"`" 2>\&1 \& wait" ;;/' \
  /usr/bin/mysqld_safe

#
# Apache Settings
#
RUN adduser --uid 1000 --gecos '' --disabled-password wocker \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
    && sed -i -e \
        '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' \
        /etc/apache2/apache2.conf \
    && sed -i -e \
        "s#DocumentRoot.*#DocumentRoot /var/www/wordpress#" \
        /etc/apache2/sites-available/000-default.conf \
    && sed -i -e \
        "s/export APACHE_RUN_USER=.*/export APACHE_RUN_USER=wocker/" \
        /etc/apache2/envvars \
    && sed -i -e \
        "s/export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=wocker/" \
        /etc/apache2/envvars \
    && a2enmod rewrite

#
# php.ini settings
#
RUN sed -i -e \
    "s/^upload_max_filesize.*/upload_max_filesize = 32M/" \
    /etc/php5/apache2/php.ini \
    && sed -i -e \
        "s/^post_max_size.*/post_max_size = 64M/" \
        /etc/php5/apache2/php.ini \
    && sed -i -e \
        "s/^display_errors.*/display_errors = On/" \
        /etc/php5/apache2/php.ini \
    && sed -i -e \
        "s/^;mbstring.internal_encoding.*/mbstring.internal_encoding = UTF-8/" \
        /etc/php5/apache2/php.ini

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
ADD wp-cli.yml /var/www
WORKDIR /var/www/wordpress
RUN sed -i -e \
    "s/^bind-address.*/bind-address = 0.0.0.0/" \
    /etc/mysql/my.cnf \
    && service mysql start \
    && mysqladmin -u root password root \
    && mysql -uroot -proot -e \
      "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8; grant all privileges on wordpress.* to wordpress@'%' identified by 'wordpress';" \
    && wp core download --allow-root \
    && wp core config --allow-root \
      --dbname=wordpress \
      --dbuser=wordpress \
      --dbpass=wordpress \
      --dbhost=localhost
RUN chown -R wocker:wocker /var/www/wordpress

#
# Open ports
#
EXPOSE 80 3306

#
# Supervisor
#
RUN mkdir -p /var/log/supervisor
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]
