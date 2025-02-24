# Use CentOS 7 as the base image
FROM centos:7

# Update the repository configuration to use the vault.centos.org mirror
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Define the Python version as a build argument, defaulting to Python 3.10 if not specified
ARG PYTHON_VERSION=3.10.12
ENV PYTON_VERSION=${PYTHON_VERSION}
ARG OPENSSL_VERSION=1.1.1

# Install dependencies required to build Python and OpenSSL
RUN yum -y update && \
    yum -y groupinstall "Development Tools" && \
    yum -y install wget bzip2-devel libffi-devel zlib-devel glibc glibc-devel && \
    yum clean all

# Install OpenSSL from source
RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar -zxf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl && \
    make && make install && \
    cd .. && rm -rf openssl-${OPENSSL_VERSION}*

# Update the shared library cache with the new OpenSSL library
RUN echo "/usr/local/openssl/lib" >> /etc/ld.so.conf.d/openssl-${OPENSSL_VERSION}.conf && ldconfig

# Download and install the specified Python version with the new OpenSSL
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --enable-optimizations --with-openssl=/usr/local/openssl && \
    make altinstall && \
    cd .. && rm -rf Python-${PYTHON_VERSION}*

# Set the installed Python version as the default for python3 and pip3 commands
RUN ln -s /usr/local/bin/python${PYTHON_VERSION:0:4} /usr/bin/python3 && \
    ln -s /usr/local/bin/pip${PYTHON_VERSION:0:4} /usr/bin/pip3

# Upgrade pip to ensure SSL works correctly
RUN python3 -m ensurepip && python3 -m pip install --upgrade pip

# Verify the installation
RUN python3 --version && pip3 --version

# Set the default command to bash
CMD ["/bin/bash"]