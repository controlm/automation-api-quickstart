## How to Automate Code Deployment

Tutorial on the [product web page](https://docs.bmc.com/docs/display/ctmSaaSAPI/Automating+code+deployment)
that explains how DevOps engineer can automate code deployment.

The bash and python examples can be used as a script of a **Jenkins** step that pushes Git changes to Control-M.

```bash
#!/bin/bash
for f in *.json; do
 echo "Deploying file $f";
 ctm deploy $f -e ciEnvironment;
done
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/ctmSaaSAPI/Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/ctmSaaSAPI/Code+Reference) documentation for more information.
