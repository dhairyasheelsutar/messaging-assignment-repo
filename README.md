# Message Web Service Application

## Objective

To develop a scalable HTTP API service for sending and receiving messages between accounts. 

The service will have the following features:

- Build APIs for getting all messages for an account, creating new messages, and searching messages based on various filters. Make sure to implement logging / error handling.
- Containerize the service using Docker with security best practices.
- Use Python/Go as the preferred language for development.
- Integrate MySQL/Postgres database for persistence.
- Deploy the webservice in Kubernetes.
- Implement zero downtime deployments, autoscaling, monitoring, and log aggregation on Kubernetes.
- Write Terraform scripts to provision a Kubernetes cluster on AWS.
- Setup firewall rules and networking.
- Build a CI/CD pipeline using Jenkins to automate deployments.

## Architecture

Here is the architecture diagram to implement the points mentioned in the Objective section:

![Architechture Diagram](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/images/architechture.png)


### Overview

The entire architecture is deployed using the terraform scripts right from provisioning the VPC to deploying webservice.

It implements Infra provisioning, CI/CD Pipelines, Scaling and Observability for the HTTP API.

Here are the details of all the components - 
1. [Terraform Deployment](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md)
2. [HTTP API](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/app/README.md)
3. [Kubernetes Spec files](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/k8s/README.md)


### Application Components

#### Webservice

The webservice (Messaging Service) is implemented using Fast API. Fast API is used because it simplifies API Development by providing features as such as Routing, Input validation etc.

We can simply provide the request schema, response schema in the router and FastAPI takes care of validating the input. This is because it uses Pydantic library under the hood.

Also, FastAPI generates the API Documentation for us.

![Fast API](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/images/fast-api.png)

The source code for the messaging service is present in the `app` directory. The tests are written in the `app/test_main.py` file.

The messaging service is deployed in the EKS cluster as `kubernetes deployment` and it is exposed internally using the `ClusterIP` service. Then the service is exposed using the `Ingress` controller. 

Since we have installed `AWS Load Balancer Controller` in the EKS cluster, the ingress resource provisions to `Application Load Balancer` and forwards the traffic to the target group. The pods are registered as IP targets in the target group.

-- Add the screenshot of the Target Group

#### Database

The database used is MySQL for storing the message data. The message schema is as follows:

+-----------------+--------------+------+-----+---------+----------------+<br />
| Field           | Type         | Null | Key | Default | Extra          |<br />
+-----------------+--------------+------+-----+---------+----------------+<br />
| id              | int          | NO   | PRI | NULL    | auto_increment |<br />
| message_id      | varchar(255) | YES  | UNI | NULL    |                |<br />
| account_id      | int          | YES  | MUL | NULL    |                |<br />
| sender_number   | varchar(255) | YES  | MUL | NULL    |                |<br />
| receiver_number | varchar(255) | YES  | MUL | NULL    |                |<br />
+-----------------+--------------+------+-----+---------+----------------+<br />

The database is deployed as a `Statefulset` in the EKS cluster. 

The MySQL database is exposed using the headless service. Headless service is a passthrough service means the it returns the Pod IPs directly when accessed through the service hostname.

The credentials such as Username, Password are passed through the environment variables.

### Networking

The VPC module is used for provisioning the network resources in the AWS Environment. It provisions the below resources:

1. 1 VPC 
2. 3 Public Subnets and 3 Private Subnets
3. Route tables for public & private subnets
4. Internet Gateway & NAT Gateway

### Kubernetes

The kubernetes cluster is deployed using the EKS service. 

#### Application

The application is deployed in the EKS in a separate namespace named `messaging-app`. Also, a new service account is provisioned for the workloads in the namespace to restrict the access.

1. `Messaging Service` - The webservice is configured to the rolling strategy with max surge and pod disruption budget with unavailable pods set to 0. This allows the service to be available at the times. In addition to this, the service is configured Guaranteed QoS class by setting the resource requests and limits. The webservice pod has a sidecar container for collecting the logs and sending it to the cloudwatch. It is also configured with the HPA, which takes care scaling the deployment based on the CPU Utilization metric.

2. `MySQL DB` - The statefulset is configured with the dynamic provisioning with the help of storage class. The storage class helps in the provisioning the EBS volumes in the AWS. Then the MySQL pod can leverage the disk by accessing it using PVC.


#### IRSA

The IAM Role for service accounts is used for granting access to the pods to the AWS Services. The works using the OIDC configuration. 

There are three instances where this is used:

1. `Writing logs to cloudwatch` - The service account present in the messaging-app namespace needs access to cloudwatch in order to send the webservice logs to it.
2. `Writing metrics to Managed Prometheus` - The prometheus server is deployed in the EKS cluster which uses `remoteWrite` configuration for writing metric data to the amazon managed prometheus.
3. `Provisioning Load Balancer` - EKS needs access to provision the ALB when an ingress resource is created.


#### Helm Charts

The terraform script is configured to deploy 2 helm charts in the EKS Cluster -

1. `AWS Load Balancer Controller` - The [helm chart](https://aws.github.io/eks-charts) is used to deploying the load balancer controller in the EKS Cluster.

2. `Prometheus Server` - A prometheus server is deployed in the EKS cluster which writes metrics to amazon managed prometheus. The values to this helm chart is present in the file `k8s/prometheus.values.yaml`. In this values file, you can see the the patterns `${<var>}` which are replaced using the terraform.

### CI/CD

The CI/CD pipeline is configured using the Jenkins. The Jenkins is deployed using terraform. A new IAM Role is created for jenkins which grants access to access EKS Cluster, Push Docker Images to ECR etc

The Jenkins VM is provisioned with the startup script which installs packages such as Jenkins, Docker, eksctl and kubectl which are used in the Jenkins Pipeline

You can find the CI/CD configuration in the `Jenkinsfile`.


1. Environment Variables: Environment variables are defined for the AWS region, AWS account ID, and the name of an Amazon Elastic Kubernetes Service (EKS) cluster.

2. Stages: The pipeline is divided into three stages.

a. Authenticate with ECR (Elastic Container Registry): Jenkins pipeline authenticates with the AWS ECR by using AWS CLI.

b. Build & Push Image: This stage builds a Docker image for an application located in the "app" directory, tags it with a unique identifier Git commit hash, and pushes it to the AWS ECR repository.

c. Deploy Application: In this stage, the pipeline replaces the ${image} pattern present in the deployment.yaml and applies it to the EKS Cluster.

![jenkins](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/images/jenkins-build.png)

### Logging & Monitoring

#### Logging

In addition to the webservice container, there is a `fluent-bit` container running in it. The `fluent-bit` container reads the logs of messaging service and sends it AWS cloudwatch. 

Both `fluent-bit` container and `webservice` are mounted on the same location where webservice writes the logs. The `fluent-bit` configs are passed using the configmap.

![cloudwatch](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/images/cloudwatch.png)

#### Monitoring

The metrics are being sent to the Managed prometheus using the prometheus server deployed in the EKS cluster. An alert is configured by monitoring the metric expression

`kube_deployment_status_condition{namespace="messaging-app"} < 1`

This metric essentially monitors whether the service is running or not. 

Here is how it is visualized using the Graphana

![graphana-monitoring](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/images/graphana-prometheus.png)

## Deployment Steps

Since everything is deployed using the terraform, the deployment steps are very simple:

1. Go the IaC directory.
2. Run the below commands

```
terraform init
terraform plan
terraform apply
```

