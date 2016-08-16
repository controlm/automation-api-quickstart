## container ready for control-m cli automation.
How to building an image with pre installed and configured automation-api cli

HOST control-m endpoint host  
USER control-m user account that will be set as the automation user.  

```bash
SRC_DIR=.
HOST=<host>
USER=<user>
PASSWORD=<password>
sudo docker build --tag=controlm \
  --build-arg HOST=$HOST \
  --build-arg USER=$USER \
  --build-arg PASSWORD=$PASSWORD $SRC_DIR
```

Running automation commands
```bash

sudo docker run              -it controlm  ctm conf servers::get

sudo docker run -v $PWD:/src -it controlm  ctm build /src/AutomationAPISampleFlow.json
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
