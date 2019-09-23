FROM centos AS builder
ENV TENGINE_VER 2.3.2
RUN yum update -y ; \
    yum install -y epel-release; \
    yum install -y wget make m4 gcc-c++  gperftools-devel     autoconf automake lua-devel  pcre-devel  libxml2-devel gd-devel perl-ExtUtils-Embed libxslt-devel GeoIP-devel openssl-devel jemalloc-devel; \
   wget https://github.com/alibaba/tengine/archive/${TENGINE_VER}.tar.gz; \
    tar zxvf ${TENGINE_VER}.tar.gz ;\
    cd tengine-${TENGINE_VER}; \
   ./configure --prefix=/usr/local/nginx --sbin-path=/usr/local/nginx/sbin/nginx \
      --conf-path=/usr/local/nginx/etc/nginx.conf --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --http-client-body-temp-path=/tmp/nginx/client_body \
      --http-proxy-temp-path=/tmp/nginx/proxy  \
      --http-fastcgi-temp-path=/tmp/nginx/fastcgi  \
      --http-uwsgi-temp-path=/tmp/nginx/uwsgi \
      --http-scgi-temp-path=/tmp/nginx/scgi \
      --pid-path=/run/nginx.pid \
      --lock-path=/run/lock/subsys/nginx \
      --user=nginx --group=nginx --with-file-aio --with-ipv6 --with-http_ssl_module \
      --with-http_realip_module --with-http_addition_module --with-http_xslt_module \
      --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module \
      --with-http_dav_module --with-http_flv_module --with-http_mp4_module  \
      --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module  \
      --with-http_secure_link_module --with-http_degradation_module  \
      --with-http_stub_status_module --with-http_perl_module --with-mail \
      --with-mail_ssl_module --with-pcre --with-pcre-jit --with-google_perftools_module \
      --with-debug --with-threads  --with-http_v2_module --with-stream \
      --add-module=./modules/ngx_http_proxy_connect_module \
      --with-cc-opt=" -O2 " --with-jemalloc;\
    make ; make install; \
    cd ..;\
    rm -rf tengine-*; \
    unlink ${TENGINE_VER}.tar.gz;

FROM centos

RUN yum install -y epel-release;\
    yum install -y  gd gperftools-libs libX11 libX11-common  libXau         libXpm  libjpeg-turbo libxcb     libxslt openssl GeoIP jemalloc perl-ExtUtils-Embed; \
    useradd -ms /bin/bash www; \
    yum clean all



    
ENV TERM xterm
VOLUME ["/tmp/nginx"]

ENV HOME /root
ENV PATH="/usr/local/nginx/bin:/usr/local/nginx/sbin:${PATH}"
WORKDIR /root

COPY nginx.conf /usr/local/nginx/etc/nginx.conf
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]

