#------------------------------------
# Control-M/Agent docker container
#------------------------------------

FROM almalinux:9.3-minimal-20231124 as base
MAINTAINER Shoshana Shandorfi <shoshana_shandorfi@bmc.com>

ARG CTMHOST
ARG USER
ARG PASSWORD

# Install necessary packages
RUN echo "Install Java, Python, and required utilities" \
    && microdnf update -y \
    && microdnf install -y shadow-utils sudo util-linux psmisc which  net-tools hostname binutils jq libnsl ncurses procps libxcrypt-compat\
    && microdnf install -y java-11-openjdk-headless --nodocs --noplugins --setopt=install_weak_deps=0 \
    && microdnf install -y python39  \
    && ln -s /usr/bin/python3.9 /usr/bin/python  \
    && python3.9 -m ensurepip  \
    && ln -s /usr/bin/pip3 /usr/bin/pip  \
    && echo "Python version: " && python --version \
    && echo "Pip version: " && pip3 --version

# Add controlm user and modify sudoers file
ARG USERNAME=controlm
RUN echo "Create $USERNAME user" \
    && useradd -d /home/$USERNAME -s /bin/bash -g 0 -m $USERNAME  \
    && chmod -R 775 /home/$USERNAME \
# Make /etc/passwd writeable by group so missing arbitrary user entry can be added
    && chmod g=u /etc/passwd

# provision Control-M/Agent and copy without these build packages
FROM base as intermediate
ARG USERNAME=controlm

# Install ctm-automation-api kit
RUN mkdir /root/ctm-automation-api \
    && cd /root/ctm-automation-api \
    && echo "Install Automation API CLI" \
    && curl --silent -k -O https://$CTMHOST:8443/automation-api/install_ctm_cli.py \
    && python install_ctm_cli.py \
    && echo "ctm cli version: "  \
    && ctm -v

USER $USERNAME
WORKDIR /home/$USERNAME
# copy run and register controlm agent script to container
COPY run_register_controlm.sh /tmp
COPY decommission_controlm.sh /tmp

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_11_openjdk
ARG AGENT_IMAGE_NAME=Agent.Linux
ENV PATH="/home/controlm/.local/bin:${PATH}"



RUN ctm env add endpoint https://$CTMHOST:8443/automation-api $USER $PASSWORD \
	&& ctm env set endpoint  \
    && cd \
    && ctm provision image $AGENT_IMAGE_NAME \
 # enable controlm agent utilities
    && echo "source /home/controlm/.bash_profile" >> /home/controlm/.bashrc \
    && cp /tmp/run_register_controlm.sh /home/controlm\
    && cp /tmp/decommission_controlm.sh /home/controlm \
    && chmod +x run_register_controlm.sh \
    && chmod +x decommission_controlm.sh

EXPOSE 7000-8000

CMD ["/home/controlm/run_register_controlm.sh"]










