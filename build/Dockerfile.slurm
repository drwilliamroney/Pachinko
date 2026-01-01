ARG UBUNTU_VERSION

FROM ${UBUNTU_VERSION}

ARG SLURM_VERSION
ARG SLURM_MD5

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl bzip2 build-essential fakeroot devscripts equivs\
                       munge libmunge-dev\
                       python3 python3-pip python3-venv\
                       dnsutils vim

ADD munge.key /etc/munge/
RUN chmod 400 /etc/munge/munge.key &&\
    chown munge /etc/munge/munge.key

RUN useradd -ms /bin/sh slurm

WORKDIR /tmp

RUN python3 -m venv .venv && \
    . .venv/bin/activate && \
    pip install jupyterlab_slurm && \
    mkdir lab && \
    curl https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2 -o slurm-${SLURM_VERSION}.tar.bz2 && \
    echo ${SLURM_MD5} slurm-${SLURM_VERSION}.tar.bz2 > slurm.md5 && \
    md5sum -c --quiet slurm.md5 && \
    tar -xvjf slurm-${SLURM_VERSION}.tar.bz2 && \
    cd slurm-${SLURM_VERSION}

WORKDIR /tmp/slurm-${SLURM_VERSION}

RUN ./configure && make install

ADD slurm.conf /usr/local/etc/slurm.conf
RUN chmod 600 /usr/local/etc/slurm*.conf && \
    chown slurm /usr/local/etc/slurm*.conf
RUN mkdir /run/slurm && \
    chown slurm /run/slurm && \
    mkdir /var/lib/slurm && \
    chown -R slurm /var/lib/slurm && \
    mkdir /var/log/slurm && \
    chown -R slurm /var/log/slurm

ADD cgroup.conf /usr/local/etc/

RUN echo "\
#!/bin/sh\n \
service munge start\n \
slurmdbd -D\n \
tail -f /dev/null\n \
"> /usr/local/bin/start_dbd.sh && \
    chmod +x /usr/local/bin/start_dbd.sh

RUN echo "\
#!/bin/sh\n \
service munge start\n \
slurmctld -D\n \
"> /usr/local/bin/start_controller.sh && \
    chmod +x /usr/local/bin/start_controller.sh

RUN echo "\
#!/bin/sh\n \
service munge start\n \
. /tmp/.venv/bin/activate\n \
jupyter lab --no-browser --allow-root --ip=0.0.0.0 --NotebookApp.token='' --NotebookApp.password=''\n \
"> /usr/local/bin/start_jupyter.sh && \
    chmod +x /usr/local/bin/start_jupyter.sh

RUN echo "\
#!/bin/sh\n \
service dbus start\n \
service munge start\n \
slurmd -N \`hostname\` -D\n \
tail -f /dev/null\n \
"> /usr/local/bin/start_node.sh && \
    chmod +x /usr/local/bin/start_node.sh

USER root
WORKDIR /tmp/lab

