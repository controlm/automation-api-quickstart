## container ready for control-m cli automation.
How to building an image with pre installed and configured automation-api cli

```bash
SRC_DIR=.
sudo docker build --tag=controlm \
  --build-arg HOST=<host> \
  --build-arg USER=<user> \
  --build-arg PASSWORD=<password> $SRC_DIR
```

Running automation commands
```bash
sudo docker run -it controlm -v /home/usr/src:/src   ctm build /src/jobs.json

sudo docker run -it controlm                         ctm conf servers::get

```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
