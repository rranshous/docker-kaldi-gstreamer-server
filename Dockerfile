FROM debian:8
MAINTAINER Eduardo Silva <zedudu@gmail.com>
MAINTAINER Robby Ranshous <rranshous@gmail.com>

RUN apt-get update && apt-get install -y  \
    autoconf \
    automake \
    bzip2 \
    g++ \
    git \
    gstreamer1.0-plugins-good \
    gstreamer1.0-tools \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-ugly  \
    libatlas3-base \
    libgstreamer1.0-dev \
    libtool-bin \
    make \
    python2.7 \
    python-pip \
    python-yaml \
    python-simplejson \
    python-gi \
    subversion \
    wget \
    zlib1g-dev && \
    apt-get clean autoclean && \
    apt-get autoremove -y && \
    pip install ws4py==0.3.2 && \
    pip install tornado && \
    ln -s /usr/bin/python2.7 /usr/bin/python ; ln -s -f bash /bin/sh

RUN cd /opt && wget http://www.digip.org/jansson/releases/jansson-2.7.tar.bz2 && \
    bunzip2 -c jansson-2.7.tar.bz2 | tar xf -  && \
    cd jansson-2.7 && \
    ./configure && make && make check &&  make install && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/jansson.conf && ldconfig && \
    rm /opt/jansson-2.7.tar.bz2 && rm -rf /opt/jansson-2.7

RUN cd /opt && \
    git clone https://github.com/kaldi-asr/kaldi && \
    cd /opt/kaldi/tools && \
    make && \
    ./install_portaudio.sh && \
    cd /opt/kaldi/src && ./configure --shared && \
    sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk && \
    make depend && make && \
    cd /opt/kaldi/src/online && make depend && make && \
    cd /opt/kaldi/src/gst-plugin && make depend && make && \
    cd /opt && \
    git clone https://github.com/alumae/gst-kaldi-nnet2-online.git && \
    cd /opt/gst-kaldi-nnet2-online/src && \
    sed -i '/KALDI_ROOT?=\/home\/tanel\/tools\/kaldi-trunk/c\KALDI_ROOT?=\/opt\/kaldi' Makefile && \
    make depend && make && \
    rm -rf /opt/gst-kaldi-nnet2-online/.git/ && \
    find /opt/gst-kaldi-nnet2-online/src/ -type f -not -name '*.so' -delete && \
    rm -rf /opt/kaldi/.git && \
    rm -rf /opt/kaldi/egs/ /opt/kaldi/windows/ /opt/kaldi/misc/ && \
    find /opt/kaldi/src/ -type f -not -name '*.so' -delete && \
    find /opt/kaldi/tools/ -type f \( -not -name '*.so' -and -not -name '*.so*' \) -delete && \
    cd /opt && git clone https://github.com/alumae/kaldi-gstreamer-server.git && \
    rm -rf /opt/kaldi-gstreamer-server/.git/ && \
    rm -rf /opt/kaldi-gstreamer-server/test/

RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y python-pip
RUN pip install --user ws4py==0.3.2

RUN mkdir /opt/models
RUN wget https://phon.ioc.ee/~tanela/tedlium_nnet_ms_sp_online.tgz -P /opt/models/
RUN cd /opt/models && tar -zxvf tedlium_nnet_ms_sp_online.tgz
RUN rm /opt/models/tedlium_nnet_ms_sp_online.tgz
RUN wget https://raw.githubusercontent.com/alumae/kaldi-gstreamer-server/master/sample_english_nnet2.yaml -P /opt/models/
RUN find /opt/models/ -type f | xargs sed -i 's:test:/opt:g'
sed -i 's:full-post-processor:#full-post-processor:g' /opt/models/sample_english_nnet2.yaml

COPY bin/client.py bin/start.sh bin/stop.sh /opt/

RUN touch /opt/worker.log && touch /opt/master.log

EXPOSE 80

RUN chmod +x /opt/start.sh && \
    chmod +x /opt/stop.sh

WORKDIR /opt

CMD /opt/start.sh -y /opt/models/sample_english_nnet2.yaml && tail -f /opt/*.log
