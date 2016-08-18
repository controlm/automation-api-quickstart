## How to build docker containers for Control-M

### Docker container for batch application 
Batch application delivered inside of docker container can use one of the following examples as base container.

Batch jobs in Control-M specify where they run. it can be on a specific host, or on a logical hostgroup
```
job1 {
   "host" : "applicative_hostgroup"
   "command" : "my_program.py"
   "runAs": "user1"
}
```
Hostgroup is a logical grouping of hosts ,Specifying a job to run on a host group, causes Control-M/Server to balance the load by directing jobs to the various hosts in the host group. Jobs will wait until at least one host is avalible in the group to start running. 

When running the docker container with the follwing parameter CTM_HOSTGROUP=applicative_hostgroup the container will self registration to the specified host group. stoping the container to unregister it from a host group.


#### centos7-agent
Example where a control-m agent is installed inside the containe.

#### alpinelinux-remotehost
Example where a container include sshd.  

### Docker container for pre installed automation api
Example of How to building container with pre installed and configured automation-api cli

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
