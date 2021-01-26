#------------------------------------
# Control-M/Agent docker container
#------------------------------------

FROM centos:7
MAINTAINER Gal Gafni Chen <gal_gafnichen@bmc.com>

ARG CTMHOST
ARG USER
ARG PASSWORD

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
	&& cd /root/ctm-automation-api \
	&& curl --silent -k -O https://$CTMHOST:8443/automation-api/ctm-cli.tgz \
	&& npm install -g ctm-cli.tgz \
	&& ctm -v \
	&& yum clean all \
        && rm -rf /var/cache/yum

# add controlm endpoint
USER controlm
# copy run and register controlm agent script to container
COPY run_register_controlm.sh /tmp
COPY decommission_controlm.sh /tmp

RUN ctm env add endpoint https://$CTMHOST:8443/automation-api $USER $PASSWORD \
	&& ctm env set endpoint \
# install java 8 
	&& sudo yum -y install java-1.8.0-openjdk \ 
# provision controlm agent image
	&& cd \
	&& ctm provision image Agent_18.Linux \
# enable controlm agent utilities
	&& echo "source /home/controlm/.bash_profile" >> /home/controlm/.bashrc \
        && cp /tmp/run_register_controlm.sh /home/controlm \
	&& cp /tmp/decommission_controlm.sh /home/controlm \
	&& chmod +x run_register_controlm.sh \
	&& chmod +x decommission_controlm.sh \
# uninstall java 8 
	&& sudo yum -y autoremove java-1.8.0-openjdk \
	&& sudo yum clean all \
        && sudo rm -rf /var/cache/yum

EXPOSE 7000-8000

CMD ["/home/controlm/run_register_controlm.sh"]
