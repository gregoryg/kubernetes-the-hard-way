#!/usr/bin/env bash
# Delete the controller and worker compute instances:


gcloud -q compute instances delete \
       $(gcloud compute instances list --filter="tags.items=k8sgcp" --format="csv(name)[no-heading]") \
       --zone $(gcloud config get-value compute/zone)

# Delete Cloud NAT and Cloud Router

gcloud -q compute routers nats delete k8sgcp-nat --router k8sgcp-router
gcloud -q compute routers delete k8sgcp-router

# Delete the external load balancer network resources:


gcloud -q compute forwarding-rules delete kubernetes-forwarding-rule \
	   --region $(gcloud config get-value compute/region)

gcloud -q compute target-pools delete kubernetes-target-pool

gcloud -q compute http-health-checks delete kubernetes

gcloud -q compute addresses delete k8sgcp

# Delete the =k8sgcp= firewall rules:


gcloud -q compute firewall-rules delete \
  k8sgcp-allow-nginx-service \
  k8sgcp-allow-internal \
  k8sgcp-allow-external \
  k8sgcp-allow-health-check

# Delete the =k8sgcp= network VPC:


gcloud -q compute routes delete \
  kubernetes-route-10-200-0-0-24 \
  kubernetes-route-10-200-1-0-24 \
  kubernetes-route-10-200-2-0-24

gcloud -q compute networks subnets delete kubernetes

gcloud -q compute networks delete k8sgcp
