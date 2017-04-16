FROM ubuntu:16.04
MAINTAINER akiray03

RUN apt-get -y update \
	&& apt-get -y install --no-install-recommends \
		git \
		curl wget \
		rake \
		ruby ruby-dev \
		bison \
		libcurl4-openssl-dev \
		libssl-dev \
		libhiredis-dev \
		libmarkdown2-dev \
		libcap-dev \
		libcgroup-dev \
		gcc make \
		libpcre3 libpcre3-dev \
		libmysqlclient-dev \
		redis-tools \
		netcat \
	&& rm -rf /var/lib/apt/lists/*

RUN cd /usr/local/src/ && git clone https://github.com/matsumotory/ngx_mruby.git
ENV NGINX_CONFIG_OPT_ENV --with-http_stub_status_module --with-http_ssl_module --prefix=/usr/local/nginx --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module
RUN cd /usr/local/src/ngx_mruby && sh build.sh && make install

EXPOSE 80
EXPOSE 443

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

COPY hook /usr/local/nginx/hook
COPY conf /usr/local/nginx/conf

CMD ["/usr/local/nginx/sbin/nginx"]
