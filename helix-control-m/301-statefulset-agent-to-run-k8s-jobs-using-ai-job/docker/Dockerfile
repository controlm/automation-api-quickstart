FROM almalinux:9.3-minimal-20231124 as base
LABEL Description="This is a Control-M/Agent image that planned to run in K8s env"

RUN echo "Update OS packages to the latest version" \
    && microdnf update -y \
    && echo "The next packages used by Control-M/Agent" \
    && echo "   binutils used for strings" \
    && echo "   hostname used for hostname" \
    && echo "   libnsl used for perl" \
    && echo "   ncurses used for installer engine" \
    && echo "   net-tools used for netstat and ss" \
    && echo "   procps used for ps" \
    && echo "   psmisc used for pstree" \
    && echo "   which used for which" \
    && echo "   sudo used for sudo" \
    && echo "Install required packages for Control-M/Agent" \
    && microdnf update -y \
        && microdnf install -y --nodocs --noplugins --setopt=install_weak_deps=0 \
             util-linux \
              psmisc \
              which \
              net-tools \
              hostname \
              binutils \
              jq \
              libnsl \
              ncurses \
              procps \
              shadow-utils \
              tar \
              tcsh \
              libxcrypt-compat \
        && microdnf install -y java-11-openjdk-headless --nodocs --noplugins --setopt=install_weak_deps=0 \
        && microdnf install -y python39  \
        && ln -s /usr/bin/python3.9 /usr/bin/python  \
        && python3.9 -m ensurepip  \
        && ln -s /usr/bin/pip3 /usr/bin/pip  \
        && echo "Python version: " && python --version \
        && echo "Pip version: " && pip3 --version \
        && curl -sL -o /tmp/kubectl "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
        && install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl \
        && kubectl version --client || exit 1 \
        && java -version || exit 1 \
        && microdnf clean all

# Add controlm user and modify sudoers file
ARG USERNAME=controlm
RUN echo "Create $USERNAME user" \
    && useradd -d /home/$USERNAME -s /bin/bash -g 0 -m $USERNAME  \
    && chmod -R 775 /home/$USERNAME \
    && echo "add $USERNAME user and root to soduers list" \
    && echo "root ALL=(ALL) ALL" >> /etc/sudoers \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers


FROM base as intermediate
ARG USERNAME=controlm
USER root

# install ctm-automation-api kitWORKDIR /root
WORKDIR /root

RUN echo "Install Automation API CLI" \
    && mkdir ctm-automation-api \
    && cd ctm-automation-api \
    && curl -sO https://controlm-appdev.s3.us-west-2.amazonaws.com/deploy/9.22.10/install_ctm_cli.py \
  #  && curl -sO https://s3-us-west-2.amazonaws.com/controlm-appdev/dev/shoshana/install_ctm_cli.py \
    && python install_ctm_cli.py \
    && ctm -v

USER controlm
WORKDIR /home/controlm

ARG AAPI_END_POINT
ARG AAPI_TOKEN
ARG AGENT_IMAGE_NAME=Agent.Linux
ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_11_openjdk
RUN echo "Provision Control-M/Agent" \
    && ctm env add tenant $AAPI_END_POINT $AAPI_TOKEN \
    && ctm provision image $AGENT_IMAGE_NAME || exit 1 \
    && ctm env del tenant \
    && echo "source .bash_profile" >> .bashrc \
    && cp -r BMCINSTALL/external_java_path* BMCINSTALL/scripts . && rm -rf BMCINSTALL/* && mv external_java_path* scripts BMCINSTALL/

ADD --chown=controlm:controlm resources/* /home/controlm/
RUN chmod +x *.sh

EXPOSE 7006
ENTRYPOINT /bin/bash -c "./startup.sh $PERSISTENT_VOL $AAPI_END_POINT $AAPI_TOKEN $AGENT_TOKEN_TAG $AGENT_HOSTGROUP_NAME"