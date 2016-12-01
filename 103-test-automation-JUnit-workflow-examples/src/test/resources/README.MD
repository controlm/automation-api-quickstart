## Changes to jobs definition files 
Make sure you change the job definition files (in the directory) to include your Control-M components if needed (ControlMServer, Host, RunAs), 
otherwise the jobs will fail or remain in wait state.



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
	     "Application": "OsApp"
	   }
      }
 }
```




