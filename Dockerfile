FROM centos:7

#Init centos
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

#Prep toinstall python
ARG PYTON_VERSION
ENV PYTON_VERSION_=${PYTON_VERSION}
RUN yum install gcc openssl-devel bzip2-devel libffi-devel gzip make -y
RUN yum install wget tar -y
WORKDIR /opt
RUN wget https://www.python.org/ftp/python/${PYTON_VERSION_}/Python-${PYTON_VERSION_}.tgz
RUN tar xzf Python-${PYTON_VERSION}.tgz
WORKDIR /opt/Python-${PYTON_VERSION}
RUN ./configure --enable-optimizations
RUN make altinstall
RUN rm -f /opt/Python-${PYTON_VERSION}.tgz

#create alias for specific version
RUN alias python${PYTON_VERSION}=/opt/Python-${PYTON_VERSION}/python

#Install pip
RUN curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py
RUN /opt/Python-${PYTON_VERSION}/python get-pip.py
RUN /opt/Python-${PYTON_VERSION}/python -m pip install --upgrade pip

WORKDIR /home
CMD ['echo "Ready to use!"']