#!/bin/bash

file_path_role=hadoopRole.json
file_path_user=hadoopUser.json
file_path_update=hadoopRoleModified.json

#Add Role
ctm config authorization:role::add ${file_path_role}

#Update Role
ctm config authorization:role::update hadoop_developers ${file_path_update}

#Add User
ctm config authorization:user::add ${file_path_user}

#Add Role to LDAP
ctm config authorization:ldap:role::add hadoop_dev_group hadoop_developers

#Change password
ctm config user:password::adminUpdate John mypass
