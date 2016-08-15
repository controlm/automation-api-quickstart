#------------------------------------------------
# Control-M Automation API build/deploy container
#------------------------------------------------

FROM alpine:latest
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

#EXPOSE 7000-8000

#CMD [""]
