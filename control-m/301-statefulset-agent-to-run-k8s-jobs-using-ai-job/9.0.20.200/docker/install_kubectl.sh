#!/bin/bash
sudo echo "[kubernetes]" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo echo "name=Kubernetes" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo echo "baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo echo "enabled=1" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo echo "gpgcheck=1" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo echo "repo_gpgcheck=1" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo echo "gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg" | sudo tee -a /etc/yum.repos.d/kubernetes.repo
sudo yum install -y kubectl
