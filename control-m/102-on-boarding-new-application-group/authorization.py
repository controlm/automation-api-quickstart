import yaml
import os
import fnmatch
import time
import sys
import requests
import json


endPoint = 'http://localhost:48080'
token = ''

#--------------------- Login API----------------------------------------
def login():	
	credentials = { "username": "<user name>", "password": "<passwrod>" } #Best practice is to pass credentials via file
	resp = requests.post(endPoint + '/session/login', json=credentials)
	
	if resp.status_code != 200:		
		raise Exception('POST /login/ {}'.format(resp.json()))
		
	data = yaml.safe_load(resp.text)
	global token
	token =	data['token']

#-------------- Role APIs --------------------------	
def add_role():

	dataFilePath = 'hadoopRole.json'
	headers={'Authorization': 'Bearer {}'.format(token)}		
	files = {'roleFile': (open(dataFilePath, "r"))}
	
	resp = requests.post(endPoint + '/config/authorization/role', files=files ,headers=headers)
	
	if resp.status_code != 200:
		print(resp.json())				
	print(resp.text)

def update_role():
	
	dataFilePath = 'hadoopRoleModified.json'
	headers={'Authorization': 'Bearer {}'.format(token)}		
	files = {'roleFile': (open(dataFilePath, "r"))}
	
	resp = requests.post(endPoint + '/config/authorization/role/hadoop_developers', files=files ,headers=headers)
	
	if resp.status_code != 200:
		print(resp.json())
		
	print(resp.text)
	
def get_role():
	
	headers={'Authorization': 'Bearer {}'.format(token)}			
	
	resp = requests.get(endPoint + '/config/authorization/role/hadoop_developers', headers=headers)
	
	if resp.status_code != 200:		
		print(resp.json())	
		
	print(resp.text)
	

def add_role_to_ldap():

	headers={'Authorization': 'Bearer {}'.format(token)}
	resp = requests.post(endPoint + '/config/authorization/ldap/hadoop_dev_group/role/hadoop_developers', headers=headers)
	
	if resp.status_code != 200:
		print(resp.json())
		
	print(resp.text)
	
def get_associates():
	
	headers={'Authorization': 'Bearer {}'.format(token)}
	resp = requests.get(endPoint + '/config/authorization/role/hadoop_dev_group/associates', headers=headers)
	
	if resp.status_code != 200:
		print(resp.json())
		
	print(resp.text)

#---------------- User APIs ----------------------------------------	
def add_user():

	dataFilePath = 'hadoopUser.json'
	headers={'Authorization': 'Bearer {}'.format(token)}		
	files = {'userFile': (open(dataFilePath, "r"))}
	
	resp = requests.post(endPoint + '/config/authorization/user', files=files ,headers=headers)
	
	if resp.status_code != 200:
		print(resp.json())
		
	print(resp.text)
	
def add_role_to_user():

	headers={'Authorization': 'Bearer {}'.format(token)}
	resp = requests.post(endPoint + '/config/authorization/user/John/role/hadoop_developers', headers=headers)
	
	if resp.status_code != 200:
		print(resp.json())
		
	print(resp.text)
	
def change_pasword():
	
	password = { "newPassword": "mypass" }
	headers={'Authorization': 'Bearer {}'.format(token)}
	resp = requests.post(endPoint + '/config/user/John/password/adminUpdate',json=password, headers=headers)
	if resp.status_code != 200:
		print(resp.json())		
		
	print(resp.text)
	
def main():
	
	login()
	add_role()
	add_user()
	update_role()	
	add_role_to_ldap()
	change_pasword()

if __name__ == '__main__':
	main()
