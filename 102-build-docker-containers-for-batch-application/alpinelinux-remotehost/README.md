## How to build docker containers for Control-M

To build container image of Control-M/Agent:
```bash
SRC_DIR=.
sudo docker build --tag=controlm_remotehost \
  --build-arg CTMHOST=<Control-M host> \
  --build-arg USER=<user> \
  --build-arg PASSWORD=<password> $SRC_DIR
```
To run & self-register the containerize as remotehost to Control-M using ssh:
```bash
sudo docker run -d -p 2222:22 -e CTM_SERVER=<Control-M/Server> \
  -e CTM_HOSTGROUP=app0 \
  -e DOCKER_HOST=<docker host> \
  -e PORT=2222 \
  -v /secrets/id_rsa.pub:/root/.ssh/authorized_keys:ro -v /mnt/data/:/data/ controlm_remotehost
```
When decommission the container it will automatically self-unregister from Control-M:
```bash
sudo docker stop $(sudo docker ps -q -f "ancestor=controlm_remotehost")
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
