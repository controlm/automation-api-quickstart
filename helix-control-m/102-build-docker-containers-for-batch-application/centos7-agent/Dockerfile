#------------------------------------
# Control-M/Agent docker container
#------------------------------------

FROM almalinux:9.3-minimal-20231124 as base
MAINTAINER Shoshana Shandorfi <shoshana_shandorfi@bmc.com>

ARG AAPI_ENDPOINT
ARG AAPI_TOKEN

# install basic packages
RUN echo "Install Java, Python, and required utilities" \
    && microdnf update -y \
    && microdnf install -y  --nodocs --noplugins --setopt=install_weak_deps=0 \
      util-linux psmisc which  net-tools hostname  binutils \
         jq \
         libnsl \
         ncurses \
         procps \
         shadow-utils \
         tar \
         tcsh \
         libxcrypt-compat \
    && microdnf install -y java-21-openjdk-headless --nodocs --noplugins --setopt=install_weak_deps=0 \
    && microdnf install -y python39  \
    && ln -s /usr/bin/python3.9 /usr/bin/python  \
    && python3.9 -m ensurepip  \
    && ln -s /usr/bin/pip3 /usr/bin/pip  \
    && echo "Python version: " && python --version \
    && echo "Pip version: " && pip3 --version \
    && microdnf clean all

# Add controlm user and modify sudoers file
ARG USERNAME=controlm
RUN echo "Create $USERNAME user" \
    && useradd -d /home/$USERNAME -s /bin/bash -g 0 -m $USERNAME  \
    && chmod -R 775 /home/$USERNAME \
# Make /etc/passwd writeable by group so missing arbitrary user entry can be added
    && chmod g=u /etc/passwd

# copy run and register controlm agent script to container
COPY run_register_controlm.sh /home/controlm/
COPY decommission_controlm.sh /home/controlm/

# provision Control-M/Agent and copy without these build packages
FROM base as intermediate
ARG USERNAME=controlm

# Install ctm-automation-api kit
RUN mkdir /root/ctm-automation-api \
    && cd /root/ctm-automation-api \
    && echo "Install Automation API CLI" \
    && curl -sO https://controlm-appdev.s3.us-west-2.amazonaws.com/deploy/9.22.10/install_ctm_cli.py \
    && python install_ctm_cli.py \
    && echo "ctm cli version: "  \
    && ctm --version


USER controlm
WORKDIR /home/controlm

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_21_openjdk

# Create AAPI env
# add controlm endpoint
RUN ctm env saas::add endpoint https://$AAPI_ENDPOINT/automation-api $AAPI_TOKEN \
	&& ctm env set endpoint \
    && echo "Do I run" \
    && cd ~/ \
    && ctm provision image Agent_Alma.Linux \
# enable controlm agent utilities
	&& echo "source /home/controlm/.bash_profile" >> /home/controlm/.bashrc \

CMD ["/home/controlm/run_register_controlm.sh"]