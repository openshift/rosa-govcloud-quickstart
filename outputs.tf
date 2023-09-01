output "next_steps" {
  value = <<EOF


***** Next steps *****

* Create your ROSA cluster:
$ rosa create cluster --cluster-name ${var.name} --mode auto --sts --version 4.11.46 \
  --machine-cidr ${aws_subnet.rosa_private[data.aws_availability_zones.available.names[0]].cidr_block} --service-cidr 172.30.0.0/16 \
  --pod-cidr 10.128.0.0/14 --host-prefix 23 --yes \
  --private-link --subnet-ids ${aws_subnet.rosa_private[data.aws_availability_zones.available.names[0]].id}

# * Once the cluster is up, create an Admin user:
# $ rosa create admin -c ${var.name}

# * Run the command provided above to log into the cluster

# * Find the URL of the cluster's console and log into it via your web browser
# $ rosa describe cluster -c ${var.name} -o json | jq -r .console.url

# * Create a sshuttle VPN via your jumphost:
# $ sshuttle --ssh-cmd 'ssh -i jumphost-key' --dns -NHr ec2-user@${aws_instance.jumphost.public_ip} ${aws_vpc.rosa.cidr_block}

EOF
  description = "ROSA cluster creation command"
}