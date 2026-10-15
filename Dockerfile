FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# Paquetes del sistema y extensiones PHP necesarios para Laravel
RUN apt-get update && \
    apt-get install -y \
        apache2 \
        php \
        libapache2-mod-php \
        php-cli \
        php-common \
        php-sqlite3 \
        php-mysql \
        php-pgsql \
        php-gd \
        php-zip \
        php-bcmath \
        php-mbstring \
        php-xml \
        php-curl \
        php-intl \
        unzip \
        zip \
        git \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Habilitamos mod_rewrite para las rutas de Laravel
RUN a2enmod rewrite

# Quitamos la página por defecto de Apache
RUN rm -f /var/www/html/index.html

# Directorio de trabajo
WORKDIR /var/www/html/

# Copiamos la aplicación Laravel
COPY ./app /var/www/html/

# Instalamos Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Dependencias de Composer
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Permisos Laravel
RUN chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database && \
    chmod -R 775 \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database

# Raíz web de Apache en public/
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Permitir .htaccess (necesario para las rutas de Laravel)
RUN printf '<Directory %s>\n    AllowOverride All\n</Directory>\n' "${APACHE_DOCUMENT_ROOT}" > /etc/apache2/conf-available/laravel.conf && \
    a2enconf laravel

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
