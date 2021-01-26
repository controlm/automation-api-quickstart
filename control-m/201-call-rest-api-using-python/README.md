# How to make REST calls to Automation API in Python

## Features:
- login by proving username, password, and hostname by command line flags
- The user will be prompted for any required inputs if they are not specified on the command line
- disable SSL Certificate Signing (Useful when testing Automation API becuase it will deploy with a self signed cert by default)
- Enable verbose mode to see more details about the calls being made
- Gives a list of jobs in the AJF
- lets the users choose one to view the output
- After viewing output the user can enter 'q' to quit or chose another job

## Usage: 
    usage: getoutput.py [-u USERNAME] [-p PASSWORD] [-h HOST] [-i] [-v] [--help]
    
    Connect to Control-M/Enterprise Manager via Automation API REST calls and display job outputs
    
    optional arguments:
      -u USERNAME, --username USERNAME
                            Username to login to Control-M/Enterprise Manager
      -p PASSWORD, --password PASSWORD
                            Passowrd to login to Control-M/Enterprise Manager
      -h HOST, --host HOST  Control-M/Enterprise Manager hostname
      -i, --insecure        Disable SSL Certification Verification
      -v, --verbose         Turn on verbose mode
      --help                show this help message and exit

- HOST is the hostname where the Automation API Rest Server is running
- USERNAME is the username used to login to Control-M
- PASSWORD is the password for that user account
- insecure will allow you to connect to an Automation API Rest Server that is using an untrusted certificate, this is useful because Automation API uses a self signed cert by default
- verbose will output the url that is being used eachtime as well as JSON header information
- help prints the above useage message

## Rest in Python
Making rest calls in python is actually fairly simple using the requests package: [http://docs.python-requests.org/en/master/](http://docs.python-requests.org/en/master/)
### To do a get on a URL:
```python
r = requests.get(www.example.com/rest/end/point) # Makes r an object conaining information about the request and the response data
print(r.text) # r.text is the raw response
print(json.dumps(json.loads(r.text)['someObjects'][0])) # if the response if in JSON and you wish to output only certain feilds you can load it as a json object
```
### To do a post on a URL:
```python
body = json.loads('{ "foo": "bar", "iAm": "postData" }') # use json.loads to make a json object to use as the post body
r = requests.post(www.example.com/rest/end/point/post, json=body) # json= automatically sets the content type for this request to json
if r.status_code == 200: # r.status_code holds the HTTP status code and can be useful for error handling in addition too the exceptions in the requests using a try except block
    exit(0)
else:
    exit(1)
```
### Headers in a request:
```python
head = json.loads('{ "foo": "bar", "iAm": "headerData" }') # just like body content for a post make a json object
r = request.get(www.example.com/rest/end/point/requires-header-data, header=head)
```