## How to build docker containers for Control-M

### Docker container for batch application 
Batch application delivered inside of docker container may use one of the following exsmples as base container.

Batch jobs in Control-M may request to run on a specific host, or on a logical HOST group

```
job1 {
   "host" : "<HOSTGROUP>"
   "command" : "my_program.py"
   "runAs": "user1"
}
```
Host group is a logical grouping of hosts ,Specifying a job to run on a host group, causes Control-M/Server to balance the load by directing jobs to the various hosts in the host group.

When running the container with the folling parameter CTM_HOSTGROUP=applicative_group the container will self registration to the specified host group. stoping the container can unregister it from a host group.



See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
