## How to build docker containers for Control-M

To build container image of Control-M/Agent:  
**CTMHOST** - Control-M endpoint host  
**USER** - Control-M user account for automation  
**PASSWORD** - Control-M account password for automation  
```bash
SRC_DIR=.
CTMHOST=<Control-M host>
USER=<user>
PASSWORD=<password>
sudo docker build --tag=controlm_remotehost \
  --build-arg CTMHOST=$CTMHOST \
  --build-arg USER=$USER \
  --build-arg PASSWORD=$PASSWORD $SRC_DIR
```
  
To run & self-register the containerize as remotehost to Control-M using ssh:  
**CTM_HOSTGROUP** - Application hostgroup  
**DOCKER_HOST** - Docker host  
**PORT** - Docker host sshd port number  
```bash
CTM_HOSTGROUP=<application_hostgroup>
DOCKER_HOST=<Doker host>
PORT=<sshd port numner>
sudo docker run -d -p $PORT:22 -e CTM_SERVER=<Control-M/Server> \
  -e CTM_HOSTGROUP=$CTM_HOSTGROUP \
  -e DOCKER_HOST=$DOCKER_HOST \
  -e PORT=$PORT \
  -v /secrets/id_rsa.pub:/root/.ssh/authorized_keys:ro -v /mnt/data/:/data/ controlm_remotehost
```
When decommission the container it will automatically self-unregister from Control-M:
```bash
sudo docker stop $(sudo docker ps -q -f "ancestor=controlm_remotehost")
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
