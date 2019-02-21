#------------------------------------
# Control-M/Agent docker container
#------------------------------------

FROM centos:7
MAINTAINER Nathan Amichay <nathan_amichay@bmc.com>

ARG CTMHOST
ARG USER
ARG PASSWORD

# install basic packages
RUN yum -y update \
	&& yum -y install wget \
	&& yum -y install unzip \
	&& yum -y install sudo \
	&& yum -y install net-tools \ 
	&& yum -y install which

# install nodejs
RUN curl --silent --location https://rpm.nodesource.com/setup_6.x | bash - \
	&& yum -y install nodejs \
	&& node -v \
	&& npm -v

# install java 8 
RUN yum -y install java-1.8.0-openjdk \
	&& java -version

# install ctm-automation-api kit
WORKDIR /root
RUN mkdir ctm-automation-api \
	&& cd ctm-automation-api \
	&& wget --no-check-certificate https://$CTMHOST:8443/automation-api/ctm-cli.tgz \
	&& npm install -g ctm-cli.tgz \
	&& ctm -v

# add controlm user and root to soduers list
RUN useradd -d /home/controlm -p controlm -m controlm \
	&& echo 'root ALL=(ALL) ALL' >> /etc/sudoers \
	&& echo 'controlm ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# add controlm endpoint
USER controlm
WORKDIR /home/controlm
RUN ctm env add endpoint https://$CTMHOST:8443/automation-api $USER $PASSWORD \
	&& ctm env set endpoint 

# provision controlm agent image
RUN cd \
	&& ctm provision image Agent.Linux

# enable controlm agent utilities
RUN echo "source /home/controlm/.bash_profile" >> /home/controlm/.bashrc

# copy run and register controlm agent script to container
COPY run_register_controlm.sh /tmp
COPY decommission_controlm.sh /tmp
RUN cp /tmp/run_register_controlm.sh /home/controlm \
	&& cp /tmp/decommission_controlm.sh /home/controlm \
	&& chmod +x run_register_controlm.sh \
	&& chmod +x decommission_controlm.sh

EXPOSE 7000-8000

CMD ["/home/controlm/run_register_controlm.sh"]
