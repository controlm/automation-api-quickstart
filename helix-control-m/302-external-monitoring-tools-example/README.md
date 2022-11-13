## Customizable Alerts Listener Implementation

Helix Control-M provides ability to integrate with external monitoring tools via web sockets.  
The file alertsListener.ts is an example of a functional alerts listener that can be used to listen to alerts that come from the Control-M system.  
The alertsListener uses websocket that is based on the ws library [ws GitHub](https://github.com/WebSocket/ws).  
This is an alternative to the alert's listener client provided by BMC through ctm cli and described in [External Alerts Management](https://docs.bmc.com/docs/automation-api/Helix21/run-service-1041161864.html#Runservice-alerts_listener_startrunalerts:listener::start:~:text=Back%20to%20top-,External%20Alert%20Management,-An%20alert%20is).

#### Running the script
```javascript
node alertsListener.js
```

The alertsListener client example reads the parameters from a Json file
### example for json file
```javascript
{
    "listenerScript": "C:\\Users\\user\\scriptExample.bat",
    "listenerEnvironment": "listenerEnvironment",
    "token": "userToken",
    "url": "wss://user-63990-alerts.us1.ci.ctmsaas.com"
}
```

listenerScript - specify the path to the alerts script that runs against every alert, provided by the customer.  
listenerEnvironment - specify the environment in which the alerts are configured  
token - api token.  
url -   WebSocket Url for the connection.
