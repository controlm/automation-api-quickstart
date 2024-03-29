FROM centos:7
LABEL Description="This is a Control-M/Agent image that planned to run in K8s env"

RUN echo "Create controlm user" \
    && useradd -d /home/controlm -s /bin/bash -m controlm  \
    && chmod -R 755 /home/controlm \
    && echo "add controlm user and root to soduers list" \
    && echo 'root ALL=(ALL) ALL' >> /etc/sudoers \
    && echo 'controlm ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN echo "Update Centos to the latest version" \
    && yum -y -q update \
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
    && yum install -y -q --noplugins --setopt=install_weak_deps=0 \
                      java-11-openjdk-headless \
                      net-tools \
                      psmisc \
                      which \
                      sudo \
    && curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && kubectl version --client || exit 1 \
    && java -version || exit 1 \
    && kubectl version --client || exit 1 \
    && yum clean all

USER controlm
WORKDIR /home/controlm

# ARG EXT_AUTO_DEPLOY=file:///home/controlm/installation
# ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=file:///home/controlm/install-configurations
ARG EXT_AUTO_DEPLOY=https://s3.amazonaws.com/bucket_name/installation
ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=https://s3.amazonaws.com/bucket_name/install-configurations
ARG AGENT_IMAGE_NAME=Agent

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_11_openjdk

RUN echo "Install Node.Js and Automation API CLI" \
    && NODEJS_VERSION="node-v16.13.0-linux-x64" \
    && export NODEJS_HOME="/home/controlm/${NODEJS_VERSION}" \
    && export PATH="$PATH:$NODEJS_HOME/bin" \
    && curl -so node.tar.xz "https://nodejs.org/dist/v16.13.0/${NODEJS_VERSION}.tar.xz" \
    && xz -d node.tar.xz \
    && tar -xf node.tar \
    && rm node.tar \
    && curl -sO https://s3-us-west-2.amazonaws.com/controlm-appdev/release/latest/ctm-cli.tgz \
    && npm install ctm-cli.tgz \
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

ADD --chown=controlm:controlm resources/* /home/controlm/
RUN chmod +x *.sh

EXPOSE 7006
ENTRYPOINT /bin/bash -c "./startup.sh $PERSISTENT_VOL $AAPI_END_POINT $AAPI_TOKEN $CTM_SERVER_NAME $AGENT_HOSTGROUP_NAME"