#!/usr/bin/python

import json
import requests
import argparse
from getpass import getpass
import urllib3
from urllib3.exceptions import *
urllib3.disable_warnings(InsecureRequestWarning)

parser = argparse.ArgumentParser(description='Connect to Control-M/Enterprise Manager via Automation API REST calls and display job outputs',add_help=False)
parser.add_argument('-u', '--username', dest='username', type=str, help='Username to login to Control-M/Enterprise Manager')
parser.add_argument('-p', '--password', dest='password', type=str, help='Passowrd to login to Control-M/Enterprise Manager')
parser.add_argument('-h', '--host', dest='host', type=str, help='Control-M/Enterprise Manager hostname')
parser.add_argument('-i', '--insecure', dest='insecure', action='store_const', const=True, help='Disable SSL Certification Verification')
parser.add_argument('-v', '--verbose', dest='verbose', action='store_const', const=True, help='Turn on verbose mode')
parser.add_argument("--help", action="help", help="show this help message and exit")

args = parser.parse_args()

verbose = args.verbose

if args.insecure:
    urllib3.disable_warnings(InsecureRequestWarning)
    verify_certs=False
else:
    verify_certs=True

host = args.host
if host == None:
    host = raw_input("EM Hostname: ")
username = args.username
if username == None:
    username = raw_input("EM username: ")
password = args.password
if password == None:
    password = getpass("Passowrd: ")
baseurl = 'https://'+host+':8443/automation-api/'

if verbose:
    print('base URL: '+baseurl)

loginurl =baseurl+'session/login'
body =json.loads('{ "password": "'+password+'", "username": "'+username+'"}')
try:
    r = requests.post(loginurl, json=body, verify=verify_certs)
except:
    print("Connecting to Automation API REST Server failed")
    quit(1)

if verbose:
    print(r.text)
    print(r.status_code)

loginresponce = json.loads(r.text)
if 'errors' in loginresponce:
    print(json.dumps(loginresponce['errors'][0]['message']))
    quit(1)

#if r.status_code != 200:
#    if json.dumps(json.loads(r.text)['errors'][0]['message'])=='"Failed to login: Incorrect username or password"':
#        print('Bad Username or Password')
#        quit(1)
if 'token' in loginresponce:
    token = json.loads(r.text)['token']
else:
    print("Failed to get token for unknown reason, exiting...")
    quit(2)

if verbose:
    print('Token: '+token)

jobstatusurl =baseurl+'run/jobs/status?token='+token

if verbose:
    print('Job Status URL: '+jobstatusurl)

r2 = requests.get(jobstatusurl, verify=verify_certs)
statuses = json.loads(r2.text)['statuses']

if verbose:
    print('statuses:\n'+json.dumps(statuses))

length = len(json.loads(r2.text)['statuses'])

if verbose:
    print('length: '+length)

x = 0
while x < length:
    print('1. '+statuses[x]['jobid']+', '+statuses[x]['name']+', '+statuses[x]['status']+', '+statuses[x]['type'])
    x +=1

selected = raw_input("Enter the it's output to view: ")

outputurl = statuses[selected]['outputURI']

if verbose:
    print(outputurl)

r3 = requests.get(outputurl, verify=verify_certs)
print(r3.text)
#x = 0
#while x < length:
#    if verbose:
#        print('Job ' + str(x) +' of ' + length + ' in in responce: ')
#    jsonobject = json.loads(r2.text)
#    if jsonobject['statuses'][x]['type'] == 'Command':
#        outputurl = jsonobject['statuses'][x]['outputURI']
#        print(outputurl)
#        r3 = requests.get(outputurl, verify=verify_certs)
#        print(r3.text)
#    x += 1