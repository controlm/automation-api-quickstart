#------------------------------------
# Control-M/Agent docker container
#------------------------------------

FROM centos:7
MAINTAINER Gal Gafni Chen <gal_gafnichen@bmc.com>

ARG AAPI_ENDPOINT
ARG AAPI_TOKEN

# install basic packages
RUN yum -y install unzip \
	&& yum -y install sudo \
	&& yum -y install net-tools \ 
	&& yum -y install which \
# install nodejs
    && curl -k --silent --location https://rpm.nodesource.com/setup_12.x | bash - \
	&& yum -y install nodejs \
	&& node -v \
	&& npm -v \
# add controlm user and root to soduers list
	&& useradd -d /home/controlm -p controlm -m controlm \
	&& echo 'root ALL=(ALL) ALL' >> /etc/sudoers \
	&& echo 'controlm ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
# install ctm-automation-api kit
	&& mkdir /root/ctm-automation-api \
	&& cd /root/ctm-automation-api \\
	&& curl --silent -k -O -H x-api-key:$AAPI_TOKEN https://$AAPI_ENDPOINT/automation-api/ctm-cli.tgz \  
	&& npm install -g ctm-cli.tgz \
	&& ctm -v \
	&& yum clean all \
    && rm -rf /var/cache/yum

# add controlm endpoint
USER controlm
WORKDIR /home/controlm

# copy run and register controlm agent script to container
COPY run_register_controlm.sh /home/controlm/
COPY decommission_controlm.sh /home/controlm/

RUN ctm env saas::add endpoint https://$AAPI_ENDPOINT/automation-api $AAPI_TOKEN \
	&& ctm env set endpoint \
# give execute permissions to start/shut scripts
	&& sudo chmod 775 /home/controlm/*controlm.sh \
# install java 8 
	&& sudo yum -y install java-1.8.0-openjdk \ 
# provision controlm agent image
	&& cd \
	&& ctm provision image Agent_CentOS.Linux \
# enable controlm agent utilities
	&& echo "source /home/controlm/.bash_profile" >> /home/controlm/.bashrc \
# uninstall java 8 
	&& sudo yum -y autoremove java-1.8.0-openjdk \
	&& sudo yum clean all \
    && sudo rm -rf /var/cache/yum


CMD ["/home/controlm/run_register_controlm.sh"]