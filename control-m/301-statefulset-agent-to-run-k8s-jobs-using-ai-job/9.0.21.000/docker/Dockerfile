FROM almalinux:9.3-minimal-20231124 as base
LABEL Description="This is a Control-M/Agent image that planned to run in K8s env"

RUN echo "Update OS packages to the latest version" \
    && echo "The following packages are used by Control-M/Agent: " \
    && echo "   binutils is used for strings" \
    && echo "   hostname is used for hostname" \
    && echo "   jq is used in startup script" \
    && echo "   libnsl is used for perl" \
    && echo "   ncurses is used for installer engine" \
    && echo "   net-tools is used for netstat and ss" \
    && echo "   procps is used for ps" \
    && echo "   psmisc is used for pstree" \
    && echo "   shadow-utils is used for useradd" \
    && echo "   tar is used by kubectl cp command" \
    && echo "   tcsh is used for tcsh" \
    && echo "   which is used for which" \
    && echo "   libxcrypt-compat is used by perl when installing AI Patch (to avoid error while loading shared libraries: libcrypt.so.1" \
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
# Make /etc/passwd writeable by group so missing arbitrary user entry can be added
    && chmod g=u /etc/passwd

# provision Control-M/Agent and copy without these build packages
FROM base as intermediate
ARG USERNAME=controlm
USER root

ADD --chown=$USERNAME:0 install-configurations /home/controlm/install-configurations/
RUN chmod -R +x /home/controlm/install-configurations/
ADD --chown=$USERNAME:0 installation /home/controlm/installation/
RUN chmod -R +x /home/controlm/installation/

#ARG EXT_AUTO_DEPLOY=file:///home/controlm/installation
#ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=file:///home/controlm/install-configurations
ARG EXT_AUTO_DEPLOY=https://s3.amazonaws.com/bucket_name/installation
ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=https://s3.amazonaws.com/bucket_name/install-configurations
ARG AGENT_IMAGE_NAME=Agent

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_21_openjdk
ENV PATH="/home/controlm/.local/bin:${PATH}"


# install ctm-automation-api kitWORKDIR /root
WORKDIR /root

RUN mkdir ctm-automation-api \
    && cd ctm-automation-api \
    && curl -sO https://s3-us-west-2.amazonaws.com/controlm-appdev/release/latest/install_ctm_cli.py \
    && python install_ctm_cli.py \
    && ctm -v

USER controlm
WORKDIR /home/controlm

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_11_openjdk

RUN echo "Provision Control-M/Agent" \
     && echo "Provision Control-M/Agent" \
        && ctm env config EXT_AUTO_DEPLOY $EXT_AUTO_DEPLOY \
        && ctm env config EXT_APPLICATION_ARTIFACTS_JSON_URL $EXT_APPLICATION_ARTIFACTS_JSON_URL \
        && ctm provision image $AGENT_IMAGE_NAME || exit 1 \
        && echo "source .bash_profile" >> .bashrc \
        && cp -r BMCINSTALL/external_java_path* BMCINSTALL/scripts . && rm -rf BMCINSTALL/* && mv external_java_path* scripts BMCINSTALL/

RUN echo "Provision Control-M Application Integrator KUBERNETES job type" \
    && source ~/.bash_profile \
    && ctm provision image AI_Kubernetes \
    && ~/ctm/cm/AI/exe-*/get_plugins | grep KUBERNETES
#
ADD --chown=controlm:controlm resources/* /home/controlm/
RUN chmod +x *.sh

EXPOSE 7006
ENTRYPOINT /bin/bash -c "./startup.sh $PERSISTENT_VOL $AAPI_END_POINT $AAPI_TOKEN $CTM_SERVER_NAME $AGENT_HOSTGROUP_NAME"