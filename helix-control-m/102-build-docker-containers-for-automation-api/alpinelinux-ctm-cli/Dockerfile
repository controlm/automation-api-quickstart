#-------------------------------------------
# Container for Control-M Automation API cli 
#-------------------------------------------

FROM mhart/alpine-node:latest
MAINTAINER Gad Ron <gad_ron@bmc.com>

ARG AAPI_ENDPOINT
ARG AAPI_TOKEN

USER root
# install nodejs
RUN apk update \
    && apk add --update nodejs nodejs-npm \
    && npm -g install npm@latest \
	&& node -v \
	&& npm -v

# install ctm-automation-api kit
WORKDIR /root
RUN mkdir ctm-automation-api \
	&& cd ctm-automation-api \
	&& wget --no-check-certificate --header=x-api-key:$AAPI_TOKEN https://$AAPI_ENDPOINT/automation-api/ctm-cli.tgz \  
	&& npm install -g ctm-cli.tgz \
	&& ctm -v 
	

# add controlm endpoint
RUN ctm env saas::add endpoint https://$AAPI_ENDPOINT/automation-api $USER $AAPI_TOKEN \
	&& ctm env set endpoint 
