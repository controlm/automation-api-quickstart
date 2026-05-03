## Automation api container
How to build a container with configured Control-M Automation API CLI

**AAPI_ENDPOINT** - Control-M endpoint host  
**AAPI_TOKEN** - Control-M automation-api token  

```bash
SRC_DIR=.
AAPI_ENDPOINT=<AAPI endpint, for example: customer-aapi.us1.controlm.com>
AAPI_TOKEN=<AAPI token>
sudo docker build --tag=controlm \
  --build-arg AAPI_ENDPOINT=$AAPI_ENDPOINT \
  --build-arg AAPI_TOKEN=$AAPI_TOKEN $SRC_DIR
```

Examples for running automation commands using the container
```bash
sudo docker run              -it controlm  ctm conf servers::get  
sudo docker run -v $PWD:/src -it controlm  ctm build /src/AutomationAPISampleFlow.json
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/ctmSaaSAPI/Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/ctmSaaSAPI/Code+Reference) documentation for more information.