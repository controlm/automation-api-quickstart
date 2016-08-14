#---------------------------------------
# Control-M Remote Host docker container
#---------------------------------------

FROM alpine:3.4
MAINTAINER Nathan Amichay <nathan_amichay@bmc.com>

ARG HOST
ARG USER
ARG PASSWORD

# install nodejs
RUN apk add --update nodejs \
  && npm -g install npm@latest \
	&& node -v \
	&& npm -v

# install ctm-automation-api kit
WORKDIR /root
RUN mkdir ctm-automation-api \
	&& cd ctm-automation-api \
	&& wget $HOST:18080/ctm-automation-api.zip \
	&& unzip ctm-automation-api.zip \
	&& npm install -g ctm-cli.tgz \
	&& ctm -v

# add controlm endpoint
RUN ctm env add endpoint http://$HOST:48080 $USER $PASSWORD \
	&& ctm env set endpoint 

# copy run and resiter controlm agent script to container
#COPY run_register_controlm.sh /tmp
#COPY decommission_controlm.sh /tmp
#RUN cp /tmp/run_register_controlm.sh /home/controlm \
#	&& cp /tmp/decommission_controlm.sh /home/controlm \
#	&& chmod +x run_register_controlm.sh \
#	&& chmod +x decommission_controlm.sh

#EXPOSE 7000-8000

#CMD ["/home/controlm/run_register_controlm.sh"]
