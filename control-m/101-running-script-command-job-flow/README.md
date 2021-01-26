## Running Script, Program and Command job flow

Tutorial on the [product web page](https://docs.bmc.com/docs/display/workloadautomation/Tutorial+-+Running+applications+and+programs+in+your+environment) that explains how to write jobs that execute Scripts, Programs and Commands.

```javascript
"CommandJob": {
    "Type": "Job:Command",
    "Command": "COMMAND"
},

"ScriptJob": {
    "Type": "Job:Script",
  	"FilePath":"SCRIPT_PATH",
  	"FileName":"SCRIPT_NAME"
}
```

See the [Automation API - Services](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Services) documentation for more information.  
See the [Automation API - Code Reference](https://docs.bmc.com/docs/display/public/workloadautomation/Control-M+Automation+API+-+Code+Reference) documentation for more information.
