FROM centos:7 as builder

ARG AAPI_END_POINT
ARG AAPI_TOKEN
ARG AAPI_CLI_URL 
ARG AGENT_IMAGE_NAME

LABEL Description="This is a Helix Control-M/Agent image that planned to run in K8s env"

# install basic packages
RUN  yum -y install wget \
        && yum -y install unzip \
        && yum -y install sudo \
        && yum -y install net-tools \
        && yum -y install which \
		&& yum -y install zlib-devel \
		&& yum -y install libffi-devel \
               && yum -y install compat-libstdc++-33.x86_64 \
		&& yum -y install psmisc \
		&& cd /usr/src \
# create controlm useruser
		&& useradd -d /home/controlm -s /bin/bash -m controlm \
		&&  chmod -R 755 /home/controlm \
# add controlm user and root to soduers list
		&& echo 'root ALL=(ALL) ALL' >> /etc/sudoers \
		&& echo 'controlm ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
		&& yum clean all \
		&& rm -rf /var/cache/yum

USER controlm
WORKDIR /home/controlm

# install nodejs + aapi cli
COPY npm_cli_silent.xml .
RUN	curl -sO $AAPI_CLI_URL \
		&& chmod +x DR5V3.9.0.20.220_Linux-x86_64.BIN \
		&& ./DR5V3.9.0.20.220_Linux-x86_64.BIN -silent npm_cli_silent.xml \
		&& rm -rf DR5V3.9.0.20.220_Linux-x86_64.BIN  \
		&& rm -rf npm_cli_silent.xml \
    && rm -ff  installed-versions.txt 
    
# Create AAPI env
RUN source ~/.bash_profile \
&& ctm env add myenv $AAPI_END_POINT $AAPI_TOKEN \
# install java 11
		&& sudo yum -y install java-11-openjdk \
        && java -version \
# install agent, setup will be done during statup
  && ctm provision image $AGENT_IMAGE_NAME && echo installation ended successfully \
	&& ctm provision image Application_Integrator_plugin.Linux \
  && ctm env del myenv 

# clean 
RUN sudo yum clean all \
		&& sudo rm -rf /var/cache/yum

# install kubectl
COPY  install_kubectl.sh .
RUN sudo chmod +x install_kubectl.sh \
&& ./install_kubectl.sh \
&& rm -rf install_kubectl.sh  

RUN echo "DISABLE_CM_SHUTDOWN Y" >> /home/controlm/ctm/data/CONFIG.dat \
                && touch /home/controlm/ctm/data/DISABLE_CM_SHUTDOWN_Y.cfg

# entry point script
COPY  container_agent_startup.sh .
# ctmhostkeep alive script 
COPY ctmhost_keepalive.sh .
RUN sudo chmod +x *.sh

USER controlm
WORKDIR /home/controlm

ENTRYPOINT /bin/bash -c "/home/controlm/container_agent_startup.sh $PERSISTENT_VOL"


