FROM debian:buster AS base

RUN echo 'deb http://deb.debian.org/debian buster-backports main' > /etc/apt/sources.list.d/backports.list

RUN apt-get -y update &&  apt-get -y install libmicrohttpd-dev libjansson-dev \
	libssl-dev libsofia-sip-ua-dev libglib2.0-dev libunwind-dev \
	libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev lua-json lua-ansicolors \
  libavutil-dev libavcodec-dev libavformat-dev libvpx-dev libopus-dev libx264-dev  \
	libconfig-dev pkg-config gengetopt libtool automake bison flex gettext \
  git cmake wget sudo rsync build-essential gtk-doc-tools graphviz doxygen golang-go  ninja-build meson \ 
  libavdevice-dev libavfilter-dev libswscale-dev \
  nginx \
  && apt-get clean 

RUN apt-get install -t buster-backports meson && apt-get clean 

WORKDIR /usr/local/src/

#libwebsockets
RUN git clone https://libwebsockets.org/repo/libwebsockets && \
  cd libwebsockets && \
  git checkout v2.4-stable && \
  mkdir build && \
  cd build && \
  cmake -DLWS_MAX_SMP=1 -DCMAKE_INSTALL_PREFIX:PATH=/usr -DCMAKE_C_FLAGS="-fpic" -DLWS_IPV6="ON" .. && \
  make && sudo make install 

#boring ssl
RUN git clone https://boringssl.googlesource.com/boringssl && \
  cd boringssl && \
  sed -i s/" -Werror"//g CMakeLists.txt && \
  mkdir -p build && \
  cd build && \
  cmake -DCMAKE_CXX_FLAGS="-lrt" .. && \
  make && \
  cd .. && \
  sudo mkdir -p /opt/boringssl && \
  sudo cp -R include /opt/boringssl/ && \
  sudo mkdir -p /opt/boringssl/lib && \
  sudo cp build/ssl/libssl.a /opt/boringssl/lib/ && \
  sudo cp build/crypto/libcrypto.a /opt/boringssl/lib/ 
  
#libsrtp
RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz  && \
  tar xfv v2.3.0.tar.gz  && \
  cd libsrtp-2.3.0  && \ 
  ./configure --prefix=/usr --enable-openssl && \
  make shared_library && sudo make install

#usrsctp
RUN git clone https://github.com/sctplab/usrsctp && \
  cd usrsctp && \
  ./bootstrap && \
  ./configure --prefix=/usr && \
  make && \
  sudo make install  

#libnice
RUN git clone https://gitlab.freedesktop.org/libnice/libnice && \
  cd libnice && \
  meson --prefix=/usr build && ninja -C build && sudo ninja -C build install
 
# janus
RUN  git clone https://github.com/meetecho/janus-gateway.git && \
  cd janus-gateway && \
  git checkout v0.10.3 && \
  sh autogen.sh  && \
  ./configure \
    --prefix=/opt/janus \
    --enable-post-processing \
    --enable-boringssl \
    --enable-data-channels \
    --disable-rabbitmq \
    --disable-mqtt \
    --enable-dtls-settimeout \
    --enable-plugin-echotest \
    --enable-plugin-recordplay \
    --enable-plugin-sip \
    --enable-plugin-videocall \
    --enable-plugin-voicemail \
    --enable-plugin-textroom \
    --enable-plugin-audiobridge \
    --enable-plugin-lua \
    --enable-plugin-streaming \ 
    --enable-all-handlers && \  
  make CFLAGS='-std=c99' && \
  make && \
  make install && make configs && ldconfig   

RUN rm -rf /usr/local/src/*

COPY conf/*.jcfg /opt/janus/etc/janus/
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY certs /opt/certs

EXPOSE 8080 8088 8089 8188 8989 7088 7889 5002 5004 8002 8004

CMD nginx && /opt/janus/bin/janus

