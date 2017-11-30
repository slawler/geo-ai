
# References:
# See https://raw.githubusercontent.com/slawler/hydro-py/master/Dockerfile

FROM alpine:3.6

MAINTAINER slawler <slawler@dewberry.com>

RUN apk --update  --repository http://dl-4.alpinelinux.org/alpine/edge/community add \
    bash \
    git \
    curl \
    ca-certificates \
    bzip2 \
    unzip \
    sudo \
    libstdc++ \
    glib \
    libxext \
    libxrender \
    tini \ 
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk" -o /tmp/glibc.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk" -o /tmp/glibc-bin.apk \
    && curl -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/2.25-r0/glibc-i18n-2.25-r0.apk" -o /tmp/glibc-i18n.apk \
    && apk add --allow-untrusted /tmp/glibc*.apk \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && rm -rf /tmp/glibc*apk /var/cache/apk/*
    
RUN  apk add --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
     binutils \
     gcc \
     gdal \
     geos \
     jpeg-dev \
     libffi-dev \
     libpq \
     linux-headers \
     mailcap \
     musl-dev \
     proj4-dev \
     postgresql \
     postgresql-client \
     postgresql-dev \
     zlib-dev && \
    rm -rf /var/cache/apk/*
    
RUN ln -s /usr/lib/libgeos_c.so.1 /usr/local/lib/libgeos_c.so
RUN ln -s /usr/lib/libgdal.so.20.1.3 /usr/lib/libgdal.so

# Configure environment
ENV CONDA_DIR=/opt/conda CONDA_VER=4.3.30
ENV PATH=$CONDA_DIR/bin:$PATH SHELL=/bin/bash LANG=C.UTF-8

# Install conda
RUN mkdir -p $CONDA_DIR && \
    echo export PATH=$CONDA_DIR/bin:'$PATH' > /etc/profile.d/conda.sh && \
    curl https://repo.continuum.io/miniconda/Miniconda2-${CONDA_VER}-Linux-x86_64.sh  -o mconda.sh && \
    /bin/bash mconda.sh -f -b -p $CONDA_DIR && \
    rm mconda.sh && \
    $CONDA_DIR/bin/conda install --yes conda==${CONDA_VER} 

RUN conda install -c anaconda jupyter pandas numpy matplotlib scipy scikit-image scikit-learn pil && \
    conda install -c conda-forge gdal keras && \
    conda remove --quiet --yes --force qt pyqt && \
    conda clean -tipsy

RUN mkdir -p /notebooks && \
    mkdir -p /data

VOLUME /notebooks
VOLUME /data
WORKDIR /notebooks

EXPOSE 8888
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["jupyter", "notebook", "--no-browser", "--allow-root", "--ip=\"*\""]
