## How to build docker containers for Control-M

### Docker container for batch application 
Batch application delivered inside of docker container may use one of the following exsmples as base container.

+ HOST GROUP
Host group is a logical grouping of hosts ,Specifying a job to run on a host group, causes Control-M/Server to balance the load by directing jobs to the various hosts in the host group.

'''
job1 {
   "host" : "<HOSTGROUP>"
   "command" : "my_program.py"
   "runAs": "user1"
}
'''

+ self registration


#### 
+ ssh demon 
+ control-m agent

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
