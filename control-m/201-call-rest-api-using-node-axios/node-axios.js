//-----------------------------------------------
// NPM
//-----------------------------------------------
const axios = require('axios')
var https = require('https');

//-----------------------------------------------
// Global Variables
//-----------------------------------------------
const endpoint = 'https://<controlmEndPoint>:8443/automation-api';
var TOKEN_URL = endpoint .concat('/session/login');
var username = 'your username';
var password = 'your password';

//-----------------------------------------------
// Functions
//-----------------------------------------------
function RestCall(method, url, data) { axios({
  method: 'post',
  url: TOKEN_URL, 
  headers: {'Content-Type': 'application/json'},
  httpsAgent: new https.Agent({ rejectUnauthorized: false }),
  data: {
    "password": password, 
    "username": username
    }
  })
  .then(response => {
    console.log(response.data);
    USER_TOKEN = response.data.token;
    console.log(USER_TOKEN);
    console.log(method);
    console.log(url);
    console.log(data);

    axios(endpoint .concat(url), {
      method: method, 
      headers: {'Authorization' : `Bearer ${USER_TOKEN}`},
      httpsAgent: new https.Agent({ rejectUnauthorized: false }),
      data: { data }
      }).then(response => {
        console.log("API Response:", response.data);
      if (response.data.statuses && Array.isArray(response.data.statuses)) {
        for ( var i = 0; i < response.data.statuses.length; i++) {
          console.log(response.data.statuses[i].name, response.data.statuses[i].status);
        }
      } else {
        console.log("Warning: response.data.statuses is missing or not an array.");
      }
        return response
      })
      .catch((error) => {
        console.log(error)
      })
  })
  .catch((error) => {
    console.log(error);
})

}

//-----------------------------------------------
// MAIN
//-----------------------------------------------
RestCall('get', '/run/jobs/status', '')

