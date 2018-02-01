FROM ubuntu:xenial

RUN apt-get update

RUN apt-get install -y git dos2unix make wget

#RUN git clone https://github.com/openresty/openresty.git

#RUN cd openresty/ \
#    && git checkout v1.11.2.5

RUN wget https://openresty.org/download/openresty-1.11.2.2.tar.gz && tar -xvf openresty-1.11.2.2.tar.gz

RUN cd openresty-1.11.2.2 \
    && apt-get install -y build-essential \
    && apt-get install -y libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl \
    && ./configure -j2 --with-pcre-jit --with-ipv6 \
    && make -j2 \
    && make install

ENV PATH=$PATH:/usr/local/openresty/luajit/bin/:/usr/local/openresty/nginx/sbin/:/usr/local/openresty/bin/

ADD files /

CMD ls -l && mv /nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
