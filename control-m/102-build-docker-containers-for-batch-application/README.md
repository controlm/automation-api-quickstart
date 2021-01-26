### Docker container for batch applications
Batch applications that requires to run in a container, can use the following examples as a base container.

Jobs in Control-M have a host attribute, either a host where the application and Control-M/Agent resides or   
a host group, a logical name for a collection of hosts.
```
job1 {
   "host" : "application_hostgroup"
   "command" : "/home/user1/scripts/my_program.py"
   "runAs": "user1"
}
```
Specifying a job to run on a host group, indicate Control-M/Server to balance the load by directing jobs to the various hosts in the host group.  
Jobs will wait until at least one host is avalible in the group to start running.  
Running the docker container with parameter CTM_HOSTGROUP=application_hostgroup, would self registry the docker instance as a host and would add it to the host group.  
Once a container instance is up and registered into Control-M, jobs waiting for "host"="application_hostgroup", will start running on it.  
stoping the container to un-register it from a host group and un-register the host from Control-M.  

### centos7-agent
Example where a Control-M/Agent is installed inside the container.

### alpinelinux-remotehost
Example where the container runs sshd and register itself in Control-M as a remote host using ssh.  

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
