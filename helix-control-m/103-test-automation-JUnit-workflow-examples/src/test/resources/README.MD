## Changes to jobs definition files 
Make sure you change the job definition files (in the directory) to include your Control-M components if needed (ControlMServer, Host, RunAs), 
otherwise the jobs will fail or remain in wait state.

Also, make sure you change AUTOMATION_API_ENDPOINT and API_KEY default values under TestAutomationApiJUnitExamples class.

######JobEndedOk.json 
```json
 {
	 "Ok": {
	   "Type": "Folder",
	   "OrderMethod": "Manual",
	   "okJob": {
	     "Type": "Job:Command",
		 "Command": "echo job ended ok",
	     "RunAs": "controlm",       <- agent's account 
         "Host": "agent_container",   <- agent's name 
	     "Application": "OsApp"
	   }
      }
 }
```




