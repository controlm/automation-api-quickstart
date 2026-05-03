#!/bin/bash
for f in *.json; do
 echo "Deploying file $f";
 ctm deploy $f -e ciEnvironment;
done
