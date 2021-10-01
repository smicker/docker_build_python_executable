# Debian buster is version 10 of debian which ends its lifecycle 2022-08-??
FROM debian:buster
SHELL ["/bin/bash", "-i", "-c"]

ARG PYTHON_VERSION=3.7.5
ARG PYINSTALLER_VERSION=4.5.1

ENV PYPI_URL=https://pypi.python.org/
ENV PYPI_INDEX_URL=https://pypi.python.org/simple
ENV PYENV_VERSION=${PYTHON_VERSION}

COPY entrypoint-linux.sh /entrypoint.sh

RUN \
    set -x \
    # update system
    && apt-get update \
    # install requirements
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
        vim \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        zlib1g-dev \
        libffi-dev \
        #optional libraries
        libgdbm-dev \
        libgdbm6 \
        uuid-dev \
        #upx
        upx \
    # required because openSSL on Ubuntu 12.04 and 14.04 run out of support versions of OpenSSL
    && mkdir openssl \
    && cd openssl \
    # latest version, there won't be anything newer for this
    && wget https://www.openssl.org/source/openssl-1.0.2u.tar.gz \
    && tar -xzvf openssl-1.0.2u.tar.gz \
    && cd openssl-1.0.2u \
    && ./config --prefix=$HOME/openssl --openssldir=$HOME/openssl shared zlib \
    && make \
    && make install \
    # modify bashrc
    && echo "alias ll='ls -lA' # Make ll print full folder and file list" >> ~/.bashrc \
    # install pyenv
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc \
    && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc \
    && source ~/.bashrc \
    && curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash \
    && echo 'eval "$(pyenv init -)"' >> ~/.bashrc \
    && source ~/.bashrc \
    # install python
    && PATH="$HOME/openssl:$PATH"  CPPFLAGS="-O2 -I$HOME/openssl/include" CFLAGS="-I$HOME/openssl/include/" LDFLAGS="-L$HOME/openssl/lib -Wl,-rpath,$HOME/openssl/lib" LD_LIBRARY_PATH=$HOME/openssl/lib:$LD_LIBRARY_PATH LD_RUN_PATH="$HOME/openssl/lib" CONFIGURE_OPTS="--with-openssl=$HOME/openssl" PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION \
    # install pip3 separately since it is not included in the python install above for some reason
    && apt-get install python3-pip -y \
    # install pyinstaller
    && pip3 install pyinstaller==$PYINSTALLER_VERSION \
    && mkdir /src/ \
    && chmod +x /entrypoint.sh

VOLUME /src/
WORKDIR /src/

ENTRYPOINT ["/entrypoint.sh"]

# Creds:
# This is created by inspiration from the git https://github.com/cdrx/docker-pyinstaller
