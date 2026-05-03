#-------------------------------------------
# Container for Control-M Automation API cli 
#-------------------------------------------

FROM python:3.12-alpine
MAINTAINER hoshana Shandorfi <shoshana_shandorfi@bmc.com>

ARG AAPI_ENDPOINT
ARG AAPI_TOKEN

USER root
# alpine not include spec pycryptodome lib.
RUN pip install --no-cache-dir pycryptodome==3.21.0

# install ctm-automation-api kit
WORKDIR /root
RUN mkdir ctm-automation-api \
	&& cd ctm-automation-api \
	&& wget https://s3-us-west-2.amazonaws.com/controlm-appdev/release/latest/install_ctm_cli.py \
    && python install_ctm_cli.py \
	&& ctm -v 
	

# add controlm endpoint
RUN ctm env saas::add endpoint https://$AAPI_ENDPOINT/automation-api $USER $AAPI_TOKEN \
	&& ctm env set endpoint 
