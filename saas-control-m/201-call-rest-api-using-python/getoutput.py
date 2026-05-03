#!/usr/bin/python

import collections
import json
import requests
import argparse
import sys
from getpass import getpass

try:
    from requests.packages.urllib3.exceptions import InsecureRequestWarning
except:
    from urllib3.exceptions import InsecureRequestWarning
    import urllib3

verbose = False
verify_certs = True

def parse_inputs():
    parser = argparse.ArgumentParser(
        description='Connect to Control-M/Enterprise Manager via Automation API REST calls and display job outputs',
        add_help=False)
    parser.add_argument('-t', '--token', dest='token', type=str,
                        help='Automation-Api token, used for identification and authorization')
    parser.add_argument('-h', '--host', dest='host', type=str, help='Automation-API API endpoint host')
    parser.add_argument('-i', '--insecure', dest='insecure', action='store_const', const=True,
                        help='Disable SSL Certification Verification')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_const', const=True,
                        help='Turn on verbose mode')
    parser.add_argument("--help", action="help", help="show this help message and exit")

    args = parser.parse_args()

    global verbose
    global verify_certs

    verbose = args.verbose
    insecure = args.insecure

    if insecure:  # Use insecure to disable verifing SSL Cert on server useful becuase Automation API will use a selfsigned cert by default
        if verbose:
            print('Disabling SSL Cert verification')
        try:
            requests.packages.urllib3.disable_warnings(InsecureRequestWarning)
        except:
            urllib3.disable_warnings(InsecureRequestWarning)
        verify_certs = False
    else:
        verify_certs = True

    host = args.host
    if host == None:
        host = input("EM Hostname: ")
    token = args.token
    if token == None:
        token = input("Automation-API token: ")

    baseurl = 'https://' + host + '/automation-api/'  # Control-M Automation API endpoint url
    login_args = collections.namedtuple('Login_Args', ['baseurl', 'token'])
    auth = login_args(baseurl, token)
    return auth  # return auth info as named pairs
	
def list_jobs(baseurl, token):    
    
    global verbose
    jobstatusurl = baseurl + 'run/jobs/status'  # url to list statuses of all the jobs in the AJF

    data = json.loads('{"x-api-key":"' + token + '"}')  # the jobs statues call should have the token in the header as JSON

    if verbose:
        print('Job Status URL: ' + jobstatusurl)
        print('Job Status Header: ' + json.dumps(data))

    r2 = requests.get(jobstatusurl, headers=data,
                      verify=verify_certs)  # do a get on the job status url returns json with all of the job status

    if 'statuses' in json.loads(r2.text):  # if statuses exsits in json response store the statuses to variable statuses
        statuses = json.loads(r2.text)['statuses']
    else:
       print('No job statuses were loaded.')  # if statuses does not exist, report it. this can happen if no jobs are in the AJF
       return(2)
    if verbose:
        print('statuses:\n' + json.dumps(statuses))

    length = len(json.loads(r2.text)['statuses'])  # check how many jobs are in statuses

    if verbose:
        print('length: ' + str(length))
    while True:
        x = 0
        while x < length:  # iterate though statuses
            # contents of python json objects can be accessed like named tupel for key value pairs and arrays for repeated objects
            # the end result is similar to jsonpath expressions statuses[3]['jobId'] is equivalent to 3.jobId, you can test and learn about jsonpath expressions here: https://jsonpath.curiousconcept.com/
            print(
            str(x) + '. ' + statuses[x]['jobId'] + ', ' + statuses[x]['name'] + ', ' + statuses[x]['status'] + ', ' +
            statuses[x]['type'])
            x += 1

        selected = input("Enter a number to see it's output, or q to quit: ")

        if selected == 'q':
            return(0)
        try:
            selected = int(selected)
            outputurl = statuses[selected]['outputURI']  # get the outputURI from the select job in statuses
            print_output(outputurl, data)
        except TypeError:
            print("Please enter either a number or q to quit")
        except ValueError:
            print("Please enter either a number or q to quit")
        except IndexError:
            print('That does not exist')

def list_servers(baseurl, token):    
    
    global verbose
    getAgentsUrl = baseurl + 'config/servers'  # url to the servers list  

    data = json.loads('{"x-api-key":"' + token + '"}')  # the jobs statues call should have the token in the header as JSON

    if verbose:
        print('Servers URL: ' + getAgentsUrl)
        print('Servers Header: ' + json.dumps(data))

    r2 = requests.get(getAgentsUrl, headers=data,
                      verify=verify_certs)  
    if verbose:
		print "Response:" + json.dumps(r2.text)
		
    if len(json.loads(r2.text)) > 0:  
        servers = json.loads(r2.text)
    else:
       print('No servers are connected to the system.')
       return(2)

    if verbose:
        print(str(len(servers)) + " servers exist in the system")
    x = 0
    while x < len(servers):  
		print(
		str(x+1) + '. Name:' + servers[x]['name'] + ', Host:' + servers[x]['host'] + ', Status:' + servers[x]['state'])
		x += 1
    return 0
		
def print_output(outputurl, data):
    global verbose
    if verbose:
        print(outputurl)

    r3 = requests.get(outputurl, headers=data,
                      verify=verify_certs)  # go a get on the outputURI, outputURI already includes the current token
    print(r3.text)  # this request returns the raw text output of the job and not json


args = parse_inputs()
print args
print "----------- list servers ------------"
list_servers(args.baseurl, args.token)
print "----------- jobs status ------------"
list_jobs(args.baseurl, args.token)
