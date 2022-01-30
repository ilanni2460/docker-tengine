FROM debian:stretch as builer
ENV TENGINE_VER 2.3.3



COPY tengine-${TENGINE_VER}.tar.gz /opt

RUN ls -al /opt

RUN    cd /opt; \
    tar zxvf tengine-${TENGINE_VER}.tar.gz ;\
    cd tengine-${TENGINE_VER}; \
    ls -al 

RUN echo "deb-src http://deb.debian.org/debian stretch main\n" >> /etc/apt/sources.list


RUN cat /etc/apt/sources.list; \
    apt-get update ; \
    apt-get dist-upgrade -y ; \
    apt-get install -y gcc make g++ wget libgoogle-perftools-dev vim-tiny libjemalloc-dev libxml2 libxml2-dev libxslt-dev; \
    apt-get build-dep nginx-full -y; \
    apt-get build-dep libnginx-mod-http-image-filter -y ;

RUN   cd /opt/tengine-2.3.3; \
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
      --with-http_realip_module --with-http_addition_module \
      --with-http_image_filter_module --with-http_geoip_module --with-http_sub_module \
      --with-http_dav_module --with-http_flv_module --with-http_mp4_module  \
      --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module  \
      --with-http_secure_link_module --with-http_degradation_module  \
      --with-http_stub_status_module --with-http_perl_module --with-mail \
      --with-mail_ssl_module --with-pcre --with-pcre-jit --with-google_perftools_module \
      --with-debug --with-threads  --with-http_v2_module --with-stream \
      --add-module=./modules/ngx_http_proxy_connect_module \
      --with-cc-opt=" -O2 -static -static-libgcc" \
            --with-ld-opt="-static" --with-cpu-opt=generic --with-jemalloc;\
    make ; make install
    

RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 \
 && chmod +x /usr/bin/dumb-init

FROM debian:stretch-slim


RUN useradd -ms /bin/bash  www;\
    rm -rf /var/lib/apt/lists/*;\
    cd ..;\
    rm -rf tengine-*; \
    unlink ${TENGINE_VER}.tar.gz;
ENV TERM xterm
VOLUME ["/tmp/nginx"]

ENV HOME /root
ENV PATH="/usr/local/nginx/bin:/usr/local/nginx/sbin:${PATH}"
WORKDIR /root
COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY --from=builder /usr/bin/dumb-init /usr/bin/dumb-init

COPY nginx.conf /usr/local/nginx/etc/nginx.conf



ENTRYPOINT [ "/usr/bin/dumb-init" , "--" ]

CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]




