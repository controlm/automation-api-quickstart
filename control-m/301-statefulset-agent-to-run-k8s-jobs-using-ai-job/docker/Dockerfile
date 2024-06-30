FROM almalinux:9.3-minimal-20231124
LABEL Description="This is a Control-M/Agent image that planned to run in K8s env"

RUN echo "Update OS packages to the latest version" \
    && echo "The following packages are used by Control-M/Agent: " \
    && echo "   hostname is used for hostname" \
    && echo "   net-tools is used for netstat and ss" \
    && echo "   procps is used for ps" \
    && echo "   psmisc is used for pstree" \
    && echo "   tar is used by kubectl cp command" \
    && echo "   xz is used for nodeJS install" \
    && echo "   libxcrypt-compat is used to avoid error while loading shared libraries: libcrypt.so.1" \
    && echo "   which used for which" \
    && echo "   sudo used for sudo" \
    && echo "Install required packages for Control-M/Agent" \
    && microdnf install -y --nodocs --noplugins --setopt=install_weak_deps=0 \
                      net-tools \
                      psmisc \
                      which \
                      sudo \
                      xz \
                      tar \
                      libxcrypt-compat \
                      hostname \
                      procps \
    && curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && kubectl version --client || exit 1 \
    && microdnf clean all

ARG USERNAME=controlm
RUN echo "Create $USERNAME user" \
    && useradd -d /home/$USERNAME -s /bin/bash -m $USERNAME  \
    && chmod -R 755 /home/$USERNAME \
    && echo "add $USERNAME user and root to soduers list" \
    && echo "root ALL=(ALL) ALL" >> /etc/sudoers \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Java for installation: will not be copied over to final image
RUN echo "Install Java and NodeJS needed for installations" \
    && microdnf install -y java-17-openjdk-headless-17.0.11.0.9-2.el9.x86_64 --nodocs --noplugins --setopt=install_weak_deps=0 \
    && microdnf install -y nodejs && echo "nodejs version: " && node -v && echo "npm version: " && npm -v

USER $USERNAME
WORKDIR /home/$USERNAME
# ARG EXT_AUTO_DEPLOY=file:///home/$USERNAME/installation
# ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=file:///home/$USERNAME/install-configurations
ARG EXT_AUTO_DEPLOY=https://s3.amazonaws.com/bucket_name/installation
ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=https://s3.amazonaws.com/bucket_name/install-configurations
ARG AGENT_IMAGE_NAME=Agent

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_17_openjdk
#COPY --chown=$USERNAME:$USERNAME installation ${EXT_AUTO_DEPLOY#file://}
#COPY --chown=$USERNAME:$USERNAME install-configurations ${EXT_APPLICATION_ARTIFACTS_JSON_URL#file://}

RUN echo "Install Node.Js and Automation API CLI" \
    && NODEJS_VERSION="node-v18.18.2-linux-x64" \
    && export NODEJS_HOME="/home/$USERNAME/${NODEJS_VERSION}" \
    && export PATH="$PATH:$NODEJS_HOME/bin" \
    && curl -so node.tar.xz "https://nodejs.org/dist/v18.18.2/${NODEJS_VERSION}.tar.xz" \
    && xz -d node.tar.xz \
    && tar -xf node.tar \
    && rm node.tar \
    && curl -sO https://s3-us-west-2.amazonaws.com/controlm-appdev/release/latest/ctm-cli.tgz \
    && npm install ctm-cli.tgz \
    && echo "ctm cli version: " && npx ctm -v \
    && echo "Provision Control-M/Agent" \
    && npx ctm env config EXT_AUTO_DEPLOY $EXT_AUTO_DEPLOY \
    && npx ctm env config EXT_APPLICATION_ARTIFACTS_JSON_URL $EXT_APPLICATION_ARTIFACTS_JSON_URL \
    && npx ctm provision image $AGENT_IMAGE_NAME || exit 1 \
    && echo "source .bash_profile" >> .bashrc \
    && rm -rf install bmcnode/$NODEJS_VERSION $NODEJS_HOME node_modules .npm ctm-cli.tgz package.json package-lock.json ctm/cm/AI/ipp \
    && cp -r BMCINSTALL/external_java_path* BMCINSTALL/scripts . && rm -rf BMCINSTALL/* && mv external_java_path* scripts BMCINSTALL/

RUN echo "Provision Control-M Application Integrator KUBERNETES job type" \
    && source ~/.bash_profile \
    && ctm provision image AI_Kubernetes \
    && ~/ctm/cm/AI/exe-*/get_plugins | grep KUBERNETES

ADD --chown=$USERNAME:$USERNAME resources/* /home/$USERNAME/
RUN chmod +x *.sh

EXPOSE 7006
ENTRYPOINT ["/bin/bash", "-c", "./startup.sh $PERSISTENT_VOL $AAPI_END_POINT $AAPI_TOKEN $CTM_SERVER_NAME $AGENT_HOSTGROUP_NAME"]