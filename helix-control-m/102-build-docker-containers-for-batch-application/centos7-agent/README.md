## How to build docker containers for Control-M

Tutorial on the [product web page](https://docs.bmc.com/docs/display/ctmSaaSAPI/Building+a+docker+container+for+batch+applications)
that explains how to build a docker container for batch applications.

To build container image of Control-M/Agent:  
**AAPI_ENDPOINT** - Control-M Automation API endpoint   
**AAPI_TOKEN** - Control-M user AAPI token

```bash
SRC_DIR=.
AAPI_ENDPOINT=<AAPI endpint, for example: customer-aapi.ci.ctmsaas.com>
AAPI_TOKEN=<AAPI token>
sudo docker build --tag=controlm \
  --build-arg AAPI_ENDPOINT=$AAPI_ENDPOINT \
  --build-arg AAPI_TOKEN=$AAPI_TOKEN $SRC_DIR
```

  
To run & self-register the containerize Control-M/Agent to Control-M:  
**AGENT_TAG** - An agent tag name (use web interface or the CLI "ctm auth tokens::get -s forAgent=true")  
**CTM_HOSTGROUP** - Application hostgroup  
```bash
CTM_HOSTGROUP=<application_hostgroup>
AGENT_TAG=<Agent tag name>
sudo docker run --net host \
  -e CTM_HOSTGROUP=$CTM_HOSTGROUP \
  -e AGENT_TAG=$AGENT_TAG -dt controlm
```

To decommission Control-M/Agent container and self-unregister from Control-M:
```bash
sudo docker exec -i -t <docker container> /home/controlm/decommission_controlm.sh
sudo docker stop <docker container>
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/ctmSaaSAPI/Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/ctmSaaSAPI/Code+Reference) documentation for more information.