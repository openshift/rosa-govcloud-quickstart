# ROSA GovCloud Quickstart

This Terraform module is a quickstart for provisioning an existing VPC to install a ROSA cluster in AWS GovCloud for demonstration purposes.

See [examples](./examples) and [https://docs.openshift.com/container-platform/4.11/installing/installing_aws/installing-aws-vpc.html](https://docs.openshift.com/container-platform/4.11/installing/installing_aws/installing-aws-vpc.html) for full requirements.

## Prerequisites
Ensure that `aws`, `terraform`, `sshuttle`, and `rosa` CLIs are installed and configured with credentials, if applicable.

## Creating the VPC
1. Clone this git repository and `cd` into it:
   ```bash
   git clone https://github.com/andykrohg/rosa-govcloud-quickstart
   cd rosa-govcloud-quickstart
   ```
2. Create an SSH key pair to use for a jumphost
   ```bash
   ssh-keygen -f jumphost-key -q -N ""
   ```
3. Initialize and apply resources with terraform:
   ```bash
   terraform init
   terraform apply
   ```

## Running the Installation
Terraform will output the command you should use to create your rosa cluster. Copy and run it to kick off the install It will look something like this:
```bash
rosa create cluster --cluster-name andy-demo-2 --mode auto --sts \
  --machine-cidr 10.0.0.0/17 --service-cidr 172.30.0.0/16 \
  --pod-cidr 10.128.0.0/14 --host-prefix 23 --yes \
  --private-link --subnet-ids subnet-03b5943cfb7921b85
```

## Accessing the Cluster
Once the installation has completed, review the next steps in cluster access from terraform like this:
```bash
terraform output next_steps
```

You'll get an output of useful commands to create an admin user and an `sshuttle` VPN tunnel to enable you to access the cluster in your browser or via CLI from your laptop. It looks something like this:
```bash
# * Once the cluster is up, create an Admin user:
# $ rosa create admin -c rosa-gc-demo

# * Run the command provided above to log into the cluster

# * Create a sshuttle VPN via your jumphost:
# $ sshuttle --ssh-cmd 'ssh -i jumphost-key' --dns -NHr ec2-user@15.200.235.209 10.0.0.0/16

# * Find the URL of the cluster's console and log into it via your web browser
# $ rosa describe cluster -c rosa-gc-demo -o json | jq -r .console.url
```
> If you don't have sshuttle installed, you can download it from github [here](https://github.com/sshuttle/sshuttle#obtaining-sshuttle).

## Cleaning Up
Delete the rosa cluster and destroy terraform assets:
```bash
rosa delete cluster
terraform destroy
```