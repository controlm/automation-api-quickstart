#---------------------------------------
# Control-M Remote Host docker container
#---------------------------------------

FROM mhart/alpine-node:latest
MAINTAINER Nathan Amichay <nathan_amichay@bmc.com>

ARG CTMHOST
ARG USER
ARG PASSWORD

#install wget openssl ca-certificates
RUN apk update \
    && apk add ca-certificates wget \
    && update-ca-certificates

# install nodejs npm
RUN apk update \
    && apk add --update nodejs nodejs-npm \
    && npm -g install npm@latest \
    && node -v \
    && npm -v

# install ctm-automation-api kit
WORKDIR /root
RUN mkdir ctm-automation-api \
	&& cd ctm-automation-api \
	&& wget --no-check-certificate https://$CTMHOST:8443/automation-api/ctm-cli.tgz \
	&& npm install -g ctm-cli.tgz \
	&& ctm -v

# add controlm endpoint
RUN ctm env add endpoint https://$CTMHOST:8443/automation-api $USER $PASSWORD \
	&& ctm env set endpoint 

# copy run and resiter controlm agent script to container
COPY run_register_controlm.sh /run_register_controlm.sh
COPY decommission_controlm.sh /decommission_controlm.sh
RUN chmod +x /run_register_controlm.sh \
	&& chmod +x /decommission_controlm.sh

# install and configure sshd
# based on https://github.com/ourtownrentals/docker-sshd
RUN apk update \
 && apk add bash git openssh rsync \
 && mkdir -p ~root/.ssh \
 && chmod 700 ~root/.ssh/ \
 && echo -e "Port 22\n" >> /etc/ssh/sshd_config \
 && echo -e "PasswordAuthentication no\n" >> /etc/ssh/sshd_config \
 && echo -e "ChallengeResponseAuthentication no\n" >> /etc/ssh/sshd_config \
 && cp -a /etc/ssh /etc/ssh.cache \
 && rm -rf /var/cache/apk/*

EXPOSE 22

COPY entry.sh /entry.sh
RUN chmod +x /entry.sh

ENTRYPOINT ["/entry.sh"]

CMD ["/usr/sbin/sshd", "-D", "-f", "/etc/ssh/sshd_config"]
