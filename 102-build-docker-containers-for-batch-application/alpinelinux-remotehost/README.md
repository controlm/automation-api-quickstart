## How to build docker containers for Control-M

To build container image of Control-M/Agent:
```bash
SRC_DIR=.
sudo docker build --tag=controlm \
  --build-arg CTMHOST=<Control-M host> \
  --build-arg USER=<user> \
  --build-arg PASSWORD=<password> $SRC_DIR
```
To run & self-register the containerize Control-M/Agent to Control-M:
```bash
sudo docker run --net host \
  -e CTM_SERVER=<host> \
  -e CTM_HOSTGROUP=app0 \
  -e CTM_AGENT_PORT=7020 -dt controlm
```
To decommission Control-M/Agent container and self-unregister from Control-M:
```bash
sudo docker exec -i -t <docker container> /home/controlm/decommission_controlm.sh
sudo docker stop <docker container>
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
