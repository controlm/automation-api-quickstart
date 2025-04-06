FROM almalinux:9.3-minimal-20231124 as base
LABEL io.k8s.description="Control-M/Agent base image for deployment on K8s infrastructure"

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
    && microdnf install -y --nodocs --noplugins --setopt=install_weak_deps=0 \
                      binutils \
                      hostname \
                      jq \
                      libnsl \
                      ncurses \
                      net-tools \
                      procps \
                      psmisc \
                      shadow-utils \
                      tar \
                      tcsh \
                      which \
                      libxcrypt-compat \
    && microdnf clean all

ARG USERNAME=controlm
RUN echo "Create $USERNAME user" \
    && useradd -d /home/$USERNAME -s /bin/bash -g 0 -m $USERNAME  \
    && chmod -R 775 /home/$USERNAME \
# Make /etc/passwd writeable by group so missing arbitrary user entry can be added
    && chmod g=u /etc/passwd

# provision Control-M/Agent and copy without these build packages
FROM base as intermediate
ARG USERNAME=controlm

# Install Java for installation: will not be copied over to final image
RUN echo "Install Java and python needed for installations" \
    && microdnf install -y java-21-openjdk-headless --nodocs --noplugins --setopt=install_weak_deps=0  \
    && microdnf install -y python39 && \
        ln -s /usr/bin/python3.9 /usr/bin/python && \
        python3.9 -m ensurepip && \
        ln -s /usr/bin/pip3 /usr/bin/pip && \
        echo "Python version: " && python --version && \
        echo "Pip version: " && pip3 --version

USER $USERNAME
WORKDIR /home/$USERNAME
ARG AGENT_IMAGE_NAME=Agent
ARG AGENT_VERSION
#ARG EXT_AUTO_DEPLOY=file:///tmp/installation
#ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=file:///tmp/install-configurations
ARG EXT_AUTO_DEPLOY=https://s3.amazonaws.com/bucket_name/installation
ARG EXT_APPLICATION_ARTIFACTS_JSON_URL=https://s3.amazonaws.com/bucket_name/install-configurations

ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_21_openjdk
#ADD --chown=$USERNAME:0 install-configurations /tmp/install-configurations/
#ADD --chown=$USERNAME:0 installation /tmp/installation/
ENV PATH="/home/controlm/.local/bin:${PATH}"

RUN echo "Install Automation API CLI" \
    && curl -sO https://s3-us-west-2.amazonaws.com/controlm-appdev/release/latest/install_ctm_cli.py \
    && python install_ctm_cli.py \
    && echo "ctm cli version: " && ctm -v \
    && echo "Provision Control-M/Agent" \
    && sed -i "s/AGENT_VERSION/${AGENT_VERSION}/g" /tmp/install-configurations/Agent.Linux.json \
    && ctm env config EXT_AUTO_DEPLOY $EXT_AUTO_DEPLOY \
    && ctm env config EXT_APPLICATION_ARTIFACTS_JSON_URL $EXT_APPLICATION_ARTIFACTS_JSON_URL \
    && ctm provision image $AGENT_IMAGE_NAME || exit 1 \
# TODO: remove the next HCU manual fix once it's part of the Agent installation. TBD: v22
    && echo "copy HCU fix file" && rm -f ctm/exe/Utils.pm && cp /tmp/installation/Utils.pm ctm/exe/  \
    && echo "copy license file" && cp /tmp/installation/*.pdf /home/$USERNAME/  \
    && echo "Cleanup AI patch installation files" && rm -rf ctm/install/* ctm/patches/* ctm/cm/AI/exe/jars_*_backup .bash_profile.back \
    && echo "source .bash_profile" >> .bashrc \
    && rm -rf install package.json package-lock.json .ctm ctm/cm/AI/ipp provision*.log \
    && cp -r BMCINSTALL/external_java_path* BMCINSTALL/scripts . && rm -rf BMCINSTALL/* && mv external_java_path* scripts BMCINSTALL/ \
    && echo "AI - adjust MaxActiveJobs to 400" && sed -i 's/<MaxActiveJobs>100<\/MaxActiveJobs>/<MaxActiveJobs>400<\/MaxActiveJobs>/' ctm/cm/AI/data/cm_container_conf.xml \
    && find ctm/proclog -type f -delete \
# Explicitly set HOME: needed by some CTM utilities
    && echo "export HOME=/home/controlm" >> /home/controlm/.bash_profile \
# Give group (root) same rights on files as owner (controlm)
    && chmod -R g=u /home/controlm


# copy only required files from intermediate stage to keep image size normalized
FROM base
ARG USERNAME=controlm
USER $USERNAME
ENV BMC_INST_JAVA_HOME=/etc/alternatives/jre_21_openjdk
EXPOSE 7006
WORKDIR /home/$USERNAME
ENV BASH_ENV=/home/$USERNAME/.bash_profile

COPY --link --from=intermediate /home/$USERNAME /home/$USERNAME/
COPY --link --chown=$USERNAME:0 --chmod=770 scripts /home/$USERNAME/
ENTRYPOINT ["/bin/bash", "-c", "./startup.sh"]

ARG BUILD_TAG
RUN echo "$BUILD_TAG $(date +%y%m%d.%H%M%S)" >> VERSION
