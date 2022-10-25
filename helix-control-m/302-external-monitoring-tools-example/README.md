## Alerts listener WebSocket client example

Helix control m provides ability to integrate with external monitoring tools via web sockets.
The file webSocket.ts is an example of a functional web socket client that can be used to listen to alerts that come from the controlm system.
The WebSocket client is based on the ws library [ws GitHub](https://github.com/WebSocket/ws).
This is an alternative to the WebSocket client provided by BMC through ctm cli.
To learn how to use WebSocket client  through ctm cli go to [External Alerts Management](https://docs.bmc.com/docs/automation-api/Helix21/run-service-1041161864.html#Runservice-alerts_listener_startrunalerts:listener::start:~:text=Back%20to%20top-,External%20Alert%20Management,-An%20alert%20is).

#### Running the script
```javascript
node webSocket.js
```

The WebSocket client example reads the parameters from a Json file
### example for json file
```javascript
{
    "listenerScript": "C:\\Users\\user\\scriptExample.bat",
    "listenerEnvironment": "listenerEnvironment",
    "token": "RENJUVFZOjE3MTQyYjFhLTNkZWEtNDA3OC1iMGQ2LThiMzgwMGYwNzA0YTo3ajZkdUdPTWZTaHNBOXdjVlBBdXVGSEJCd3JiNy9LZlRqQzhQalh0Q2xZPQ==",
    "url": "wss://user-63990-alerts.us1.ci.ctmsaas.com",
    "attachedMode": "false"
}
```
