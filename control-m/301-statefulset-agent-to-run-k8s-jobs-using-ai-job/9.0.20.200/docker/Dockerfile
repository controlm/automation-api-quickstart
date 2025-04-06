FROM almalinux:9.3-minimal-20231124 as base

ARG AAPI_END_POINT
ARG AAPI_USER
ARG AAPI_PASS
ARG AGENT_IMAGE_NAME
ARG CTM_SERVER_NAME

LABEL Description="This is a Control-M/Agent image that planned to run in K8s env"

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
    && curl -sO https://s3-us-west-2.amazonaws.com/controlm-appdev/release/latest/install_ctm_cli.py \
    && python install_ctm_cli.py \
    && echo "ctm cli version: "  \
    && ctm -v


USER controlm
WORKDIR /home/controlm

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_11_openjdk

# Create AAPI env
RUN ctm env add myenv $AAPI_END_POINT $AAPI_USER $AAPI_PASS \
        && java -version \
        && ctm env set myenv  \
        && cd ~\
 # install agent, setup will be done during statup
		&& ctm provision image $AGENT_IMAGE_NAME && echo installation ended successfully \
        && ctm env del myenv \
# Persistent connection : internal AR keep-alive
		&& echo "AR_PING_TO_SERVER_IND Y" >> /home/controlm/ctm/data/CONFIG.dat \
		&& echo "AR_PING_TO_SERVER_INTERVAL 30" >> /home/controlm/ctm/data/CONFIG.dat \
		&& echo "AR_PING_TO_SERVER_TIMEOUT 60" >> /home/controlm/ctm/data/CONFIG.dat \
# clean and uninstall java 11
		&& rm -rf install package.json package-lock.json ctm/cm/AI/ipp \
        && cp -r BMCINSTALL/external_java_path* BMCINSTALL/scripts . && rm -rf BMCINSTALL/* && mv external_java_path* scripts BMCINSTALL/

# install kubectl
USER root
COPY  install_kubectl.sh .
RUN sed -i 's/\r$//' install_kubectl.sh
RUN chmod +x install_kubectl.sh
RUN ./install_kubectl.sh
##
RUN echo "DISABLE_CM_SHUTDOWN Y" >> /home/controlm/ctm/data/CONFIG.dat \
                && touch /home/controlm/ctm/data/DISABLE_CM_SHUTDOWN_Y.cfg
# entry point script
COPY  container_agent_startup.sh .
# agent configuration file
COPY agent_configuration.json .
# ctmhostkeep alive script
COPY ctmhost_keepalive.sh .

EXPOSE 7006



USER controlm
WORKDIR /home/controlm

ENTRYPOINT /bin/bash -c "/home/controlm/container_agent_startup.sh $PERSISTENT_VOL $AAPI_END_POINT $AAPI_USER $AAPI_PASS $CTM_SERVER_NAME $AGENT_HOSTGROUP_NAME"


