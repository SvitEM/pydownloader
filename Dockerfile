# Use the official CentOS 7 base image
FROM centos:7

# Set the container environment
ENV container docker

# Argument for Python version
ARG PYTHON_VERSION
ENV PYTHON_VERSION=${PYTHON_VERSION}

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*


# Install EPEL repository and essential build tools
RUN yum update -y 
RUN yum install -y epel-release 
RUN yum install -y gcc openssl-devel bzip2-devel libffi-devel \
                   make wget tar xz 
# RUN  yum clean all

# Install OpenSSL 1.1 for Python 3.11 compatibility
RUN yum install -y openssl11 openssl11-devel
RUN yum clean all
RUN ln -sf /usr/include/openssl11 /usr/include/openssl
RUN ln -sf /usr/lib64/libssl.so.1.1 /usr/lib64/libssl.so
RUN ln -sf /usr/lib64/libcrypto.so.1.1 /usr/lib64/libcrypto.so

# Copy requirements file
COPY tmp/requirements_libs.txt /home/requirements.txt

# Download and install Python
WORKDIR /opt
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
RUN tar -xzf Python-${PYTHON_VERSION}.tgz
RUN cd Python-${PYTHON_VERSION} && \
    sed -i 's/PKG_CONFIG openssl /PKG_CONFIG openssl11 /g' configure &&\
    ./configure --enable-optimizations && \
    make altinstall && \
    cd .. && \
    rm -rf Python-${PYTHON_VERSION} Python-${PYTHON_VERSION}.tgz

# Create symlink for the installed Python version
RUN ln -s /usr/local/bin/python${PYTHON_VERSION%.*} /usr/local/bin/python3 && \
    ln -s /usr/local/bin/python${PYTHON_VERSION%.*} /usr/local/bin/python

# Install pip using the installed Python version
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN /usr/local/bin/python get-pip.py
RUN /usr/local/bin/python -m pip install --upgrade pip
RUN rm -f get-pip.py

RUN mkdir /home/requirements
# Set the working directory and command
WORKDIR /home
CMD ["bash", "-c", "echo Ready to use!"]
