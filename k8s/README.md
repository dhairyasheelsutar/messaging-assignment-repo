# Kubernetes YAML Spec Files

This README provides a comprehensive overview of the Kubernetes YAML files in the given directory `/home/dhairyasheel/Projects/messaging-assignment-repo/k8s`. It describes what each file contains, their purpose, and how they contribute to the deployment of a messaging application.

## Deployment Steps

The provided YAML Files are deployed using the terraform scripts. But if you want to deploy it manually, you can follow below steps:

1. Make sure you have `aws cli` and `kubectl` installed on your machine or VM.
2. Make sure that you have the EKS Cluster Running.
3. Clone the repository and go to the `k8s` directory.
4. Replace any instance `${<var>}` patterns present in the source code. They are automatically replaced when running through terraform.
5. Run the below commmand

```bash
kubectl apply -f <filename>.yaml
```


## Directory Structure

Let's understand the directory structure and the content of each file for deployment:

1. `namespace.yaml`: This file defines a Kubernetes namespace named "messaging-app." Namespaces are used to isolate resources and provide a logical boundary for our application.
2. `secret.yaml`: Defines a Kubernetes secret named "messaging-app-db-secret" in the "messaging-app" namespace, which holds sensitive data like the database password.
3. `service-account.yaml`: Defines a ServiceAccount named "messaging-service-account" for use by pods in the "messaging-app" namespace.
4. `sc.yaml`: Defines a Kubernetes StorageClass named "ebs-sc" for dynamic provisioning of Amazon Elastic Block Store (EBS) volumes with certain parameters.
5. `statefulset.yaml`: Deploys a StatefulSet named "messaging-db" that manages a MySQL database with persistent storage. It also specifies a network policy for this StatefulSet to control incoming traffic.
6. `dbservice.yaml`: Defines a Kubernetes service named "messaging-db-service" to provide cluster-internal connectivity to the MySQL database.
7. `np.yaml`: This NetworkPolicy file specifies rules for network access control. It allows ingress traffic to the MySQL StatefulSet from pods labeled as "app: webservice."
8. `deployment.yaml`: Deploys a Kubernetes Deployment named "messaging-webservice" for the messaging application. It defines the desired state for the application, including the number of replicas and the container specifications.
9. `hpa.yaml`: Defines a Horizontal Pod Autoscaler (HPA) for the "messaging-webservice" Deployment. It automatically adjusts the number of replicas based on CPU utilization.
10. `webservice.yaml`: Creates a Kubernetes Service named "messaging-service" that exposes the "messaging-webservice" Deployment internally within the cluster on port 8080.
11. `pdb.yaml`: Sets a Pod Disruption Budget for the "messaging-webservice" Deployment, ensuring that no more than the specified number of pods are disrupted simultaneously.
12. `ingress.yaml`: Configures an Ingress resource named "messaging-lb" to manage external access to the "messaging-service" using an Application Load Balancer (ALB).
13. `alertmanager.yaml`: This file defines a Prometheus alerting rule for the "WebserviceOnlineStatus" based on deployment conditions. It is not directly related to the core application deployment.


