#!/usr/bin/env bash
# Create the =k8sgcp= custom VPC network:

gcloud compute networks create k8sgcp --subnet-mode custom

# Create the =kubernetes= subnet in the =k8sgcp= VPC network:

gcloud compute networks subnets create kubernetes \
  --network k8sgcp \
  --range 10.240.0.0/24

# Create the Cloud NAT and Cloud Router for outbound internet access

gcloud compute routers create k8sgcp-router \
    --network k8sgcp

gcloud compute routers nats create k8sgcp-nat \
    --router=k8sgcp-router \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges \
    --enable-logging

# Create a firewall rule that allows internal communication across all protocols:


gcloud compute firewall-rules create k8sgcp-allow-internal \
  --allow tcp,udp,icmp \
  --network k8sgcp \
  --source-ranges 10.240.0.0/24,10.200.0.0/16

# Create a firewall rule that allows external SSH, ICMP, and HTTPS:


gcloud compute firewall-rules create k8sgcp-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network k8sgcp \
  --source-ranges 0.0.0.0/0

# Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:


gcloud compute addresses create k8sgcp \
  --region $(gcloud config get-value compute/region)

# Create three compute instances which will host the Kubernetes control plane:

CONTROL_INSTANCE_TYPE=n1-standard-2
for i in 0 1 2; do
    echo $i
    gcloud compute instances create gg-controller-${i} \
           --async \
           --no-address \
           --boot-disk-size 200GB \
           --can-ip-forward \
           --image-family ubuntu-1804-lts \
           --image-project ubuntu-os-cloud \
           --machine-type ${CONTROL_INSTANCE_TYPE} \
           --private-network-ip 10.240.0.1${i} \
           --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
           --subnet kubernetes \
           --tags k8sgcp,controller \
           --labels owner=ggrubbs,expiration=48h
done

# Create ${NUM_WORKERS} compute instances which will host the Kubernetes worker nodes:

WORKER_INSTANCE_TYPE=n1-standard-4
NUM_WORKERS=3
for i in $(seq 0 $((${NUM_WORKERS} - 1))) ; do
    echo $i
    gcloud compute instances create gg-worker-${i} \
           --async \
           --no-address \
           --boot-disk-size 200GB \
           --can-ip-forward \
           --image-family ubuntu-1804-lts \
           --image-project ubuntu-os-cloud \
           --machine-type ${WORKER_INSTANCE_TYPE} \
           --metadata pod-cidr=10.200.${i}.0/24 \
           --private-network-ip 10.240.0.2${i} \
           --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
           --subnet kubernetes \
           --tags k8sgcp,worker \
           --labels owner=ggrubbs,expiration=48h
done
