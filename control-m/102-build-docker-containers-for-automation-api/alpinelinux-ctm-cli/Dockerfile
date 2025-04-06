#-------------------------------------------
# Container for Control-M Automation API cli 
#-------------------------------------------

FROM python:3.12-alpine
MAINTAINER Shoshana Shandorfi <shoshana_shandorfi@bmc.com>

ARG CTMHOST
ARG USER
ARG PASSWORD

# alpine not include spec pycryptodome lib.
RUN pip install --no-cache-dir pycryptodome==3.21.0

# Install Control-M Automation API CLI
WORKDIR /root
RUN mkdir ctm-automation-api \
  && cd ctm-automation-api \
  && wget --no-check-certificate https://$CTMHOST:8443/automation-api/install_ctm_cli.py \
  && python install_ctm_cli.py \
  && ctm -v


# add controlm endpoint
RUN ctm env add endpoint https://$CTMHOST:8443/automation-api $USER $PASSWORD \
	&& ctm env set endpoint
