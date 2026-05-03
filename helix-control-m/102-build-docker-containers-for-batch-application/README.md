### Docker container for batch applications
For batch applications that should run in a container, use the following examples as a base container.

Jobs in Control-M have a host attribute, either a host where the application and the Agent reside or a host group, which is a logical name for a collection of hosts.
```
job1 {
   "host" : "application_hostgroup"
   "command" : "/home/user1/scripts/my_program.py"
   "runAs": "user1"
}
```
Specifying a job to run on a host group enables Control-M to balance the load by directing jobs to the various hosts in the host group.  
Jobs will wait until a host is avalible in the group to start running.  
Running the docker container with parameter CTM_HOSTGROUP=application_hostgroup self-registers the docker instance as a host and adds it to the host group.  
Once a container instance is up and registered into Control-M, jobs waiting for "host"="application_hostgroup" will start running.  

#### centos7-agent
Example where an Agent is installed in the container.
When the container starts it registers the agent in Control-M
To remove the agent from the hostgroup, run decommission_controlm.sh script before stopping the container.  


See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
