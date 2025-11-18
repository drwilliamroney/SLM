ARG UBUNTU_VERSION

FROM ${UBUNTU_VERSION}

ARG SLURM_VERSION
ARG SLURM_MD5

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl\
                       bzip2\
                       build-essential\
                       fakeroot\
                       devscripts\
                       equivs\
                       munge\
                       dnsutils

WORKDIR /tmp

RUN curl https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 -o slurm-${SLURM_VERSION}.tar.bz2 && \
    echo ${SLURM_MD5} slurm-${SLURM_VERSION}.tar.bz2 > slurm.md5 && \
    md5sum -c --quiet slurm.md5

RUN tar -xvjf slurm-${SLURM_VERSION}.tar.bz2 && \
    cd slurm-${SLURM_VERSION} && \
    mk-build-deps debian/control && \
    apt-get install -y ./*.deb && \
    debuild -b -uc -us && \
    cd .. && \
    apt install -f -y ./slurm-smd_*.deb ./slurm-smd-client_*.deb ./slurm-smd-slurmctld_*.deb ./slurm-smd-slurmdbd_*.deb ./slurm-smd-slurmd_*.deb

RUN useradd -ms /bin/sh slurm

ADD docker/slurm.conf /etc/slurm/slurm.conf
ADD docker/slurmdbd.conf /etc/slurm/slurmdbd.conf

RUN chmod 640 /etc/slurm/*.conf &&\
    chown root:root /var/log/munge &&\
    chown root:root /var/lib/munge &&\
    chown root:root /etc/munge/munge.key && \
    chown root:root /etc/munge && \
    mkdir /run/munge

RUN echo "\
#!/bin/sh\n \
munged\n \
slurmdbd -D\n \
"> /usr/sbin/startdbd.sh && \
    chmod +x /usr/sbin/startdbd.sh












