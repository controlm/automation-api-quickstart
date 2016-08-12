## How to Automate Code Deployment

[Tutorial](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Getting+Started+Guide#Control-MAutomationAPI-GettingStartedGuide-GS_for_DevOps)
that explains how DevOps engineer can automate code deployment.

The bash an python examples fit as scriplet of **Jenkins** job step that push Git changes to Control-M.

```bash
#!/bin/bash
for f in *.json; do
 echo "Deploying file $f";
 ctm deploy $f -e ciEnvironment;
done
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
