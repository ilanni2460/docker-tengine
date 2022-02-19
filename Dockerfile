FROM ubuntu:jammy as builer
ENV TENGINE_VER 2.3.3


COPY sources.list /etc/apt/sources.list
COPY tengine-${TENGINE_VER}.tar.gz /tmp/

RUN    cd /tmp/; \
    tar zxvf tengine-${TENGINE_VER}.tar.gz ;\
    cd tengine-${TENGINE_VER}; \
    ls -al 

RUN sed -i "/^# deb-src/ s/^# //" /etc/apt/sources.list

RUN cat /etc/apt/sources.list; \
    apt-get update ; \
    apt-get dist-upgrade -y ; \
    apt-get install -y gcc make g++ wget libgoogle-perftools-dev vim-tiny libjemalloc-dev libxml2 libxml2-dev libxslt-dev libgd-dev; \
    apt-get build-dep nginx-full -y;  \
    apt-get build-dep libnginx-mod-http-image-filter -y;
RUN   cd /tmp/tengine-2.3.3; \
      ./configure --prefix=/usr/local/nginx \
      --sbin-path=/usr/local/nginx/sbin/nginx \
      --conf-path=/usr/local/nginx/etc/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --http-client-body-temp-path=/tmp/nginx/client_body \
      --http-proxy-temp-path=/tmp/nginx/proxy  \
      --http-fastcgi-temp-path=/tmp/nginx/fastcgi  \
      --http-uwsgi-temp-path=/tmp/nginx/uwsgi \
      --http-scgi-temp-path=/tmp/nginx/scgi \
      --pid-path=/run/nginx.pid \
      --lock-path=/run/lock/subsys/nginx \
      --user=nginx \
      --group=nginx \
      --with-file-aio \
      --with-ipv6 \
      --with-http_ssl_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_image_filter_module \
      --with-http_geoip_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_degradation_module \
      --with-http_stub_status_module \
      --with-http_auth_request_module \
      --with-http_slice_module \
      --with-http_concat_module \
      --with-http_sysguard_module \
      --with-http_dyups_module \
      --with-http_perl_module \
      --with-http_v2_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-pcre \
      --with-pcre-jit \
      --with-google_perftools_module \
      --with-debug \
      --with-threads \
       --with-compat \
      --with-stream \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-stream_realip_module \
      --with-stream_geoip_module=dynamic \
      --with-cc-opt="-O2 -static -static-libgcc" \
      --with-ld-opt="-static" \
      --with-cpu-opt=generic \
      --with-jemalloc \
      --with-http_upstream_check_module \
      --with-http_upstream_consistent_hash_module \
      --with-sha1-asm \
      --with-md5-asm \
      --with-http_spdy_module \
      --with-http_xslt_module \
      --with-http_upstream_ip_hash_module=shared \
      --with-http_upstream_least_conn_module=shared \
      --with-http_upstream_session_sticky_module=shared \
      --with-http_map_module=shared \
      --with-http_user_agent_module=shared \
      --with-http_split_clients_module=shared \
      --with-http_access_module=shared \
      --with-http_image_filter_module=shared \
      --add-module=modules/ngx_http_upstream_check_module \
      --add-module=modules/headers-more-nginx-module-0.33 \
      --add-module=modules/ngx_http_upstream_session_sticky_module \
      --add-module=./modules/ngx_http_proxy_connect_module ;\
    make ; make install
    

RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 \
 && chmod +x /usr/bin/dumb-init

FROM ubuntu:jammy


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
