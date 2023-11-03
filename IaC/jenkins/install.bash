#!/bin/bash

# Update packages
yum update -y
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum upgrade
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install git -y
yum -y install terraform
yum install java-11-amazon-corretto-headless -y
yum install jenkins -y
systemctl restart jenkins
systemctl enable jenkins

# Install Docker
yum install docker -y
usermod -a -G docker ec2-user
systemctl start docker
systemctl enable docker