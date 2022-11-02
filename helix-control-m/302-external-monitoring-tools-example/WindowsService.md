## Configuring the Alerts Listener as a Windows Service

This procedure describes how to configure an alerts_listener system service on a Windows operating system.
You can use this service instead of the Automation API commands to start or stop alerts listening.

### Before You Begin

Ensure successful completion of the following steps described in [Setting Up External Alerts](https://documents.bmc.com/supportu/dev-saas/en-US/Documentation/Alerts.htm#Setting).
1. Enable external alerts.
2. (Optional) Submit a template to configure alert details.
3. Set the Helix Control-M environment.
4. Submit a script with details of external alert handling


### Begin
Use a wrapper executable such as [WinSW](https://github.com/winsw/winsw)
(Windows Service Wrapper), Or [NSSM](https://nssm.cc/scenarios)
(Non-Sucking Service Manager) to register the ctm.cmd executable of 
[Control-M Automation API CLI](https://docs.bmc.com/docs/saas-api/setting-up-the-api-946711372.html#SettinguptheAPI-ctm_cliInstallingtheControl-MAutomationAPICLI)
as a system service named alerts_listener, as follows:

- #### WinSW

Create a configuration file with the details of the service, as in the following example:
```xml
<service>
	<id>alerts_listener</id>
	<name>Control-M Alerts Listener</name>
	<description>This service runs Control-M Alerts Listener</description>
	<executable>@{CTM_CLI_PATH}\ctm.cmd</executable>
	<startarguments>run alerts:listener::start</startarguments>
	<stopexecutable>@{CTM_CLI_PATH}\ctm.cmd</stopexecutable>
	<stoparguments>run alerts:listener::stop</stoparguments>
	<startmode>Manual</startmode>
	<onfailure action="restart"/>
	<log mode="roll"/>
	<logpath>%CTM_CLI_PROFILE_PATH%\logs</logpath>
</service>
```
Submit your configuration file when you install the service by running the following command:
**alerts_listener install**

- #### NSSM

Install the **alerts_listener** service using the following command

**nssm install alerts_listener**

In the NSSM Service Installer, define the path to the **ctm.cmd** executable in the **Application** tab and the credentials of your Control-M user account in the **Log on** tab.
From a command line, run the **alerts_listener** service with one of the following commands:
- ***start***
- ***stop***

