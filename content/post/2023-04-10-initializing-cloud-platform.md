---
title: "Initializing a Personal Cloud Platform with Kubernetes"
date: 2023-04-10T20:58:12-04:00
draft: false
---

Over the past few months, I have been building a small scale Kubernetes platform to host open source software for personal usage and hobby projects.
The main goals for this infrastructure include:

* Enough reliability for light, daily usage
* Enough durability of persistent data to stop depending on proprietary cloud storage systems like Dropbox
* An easy way to scale up compute resources in modest increments
* Management through infrastructure as code
* Built (mostly) with open source software

This blog post explains these requirements further along with the few lines of Terraform used to initialize the platform.
Future blog posts will cover design decisions, service deployments, tooling experimentation, unexpected problems, and more interesting developments throughout the process of building the platform.

# Why Kubernetes?

You’re probably wondering why I chose to use Kubernetes given its complexity and resource-intensive nature.
There are plenty of other, simpler solutions, but I specifically want to improve my Kubernetes skills and experiment in ways I can't through work easily:

* Test out different tools in the [Cloud Native Computing Foundation (CNCF) landscape](https://landscape.cncf.io), analyze their trade-offs, and form opinions on them
* Run into problems where the stakes of failure are low
* Stay on the latest versions of tooling and try out cutting-edge features

The platform will be much more complex than necessary to run the services I’m looking to run.
That’s intentional, and that’s what will make this a fun hobby project!
The journey will be much more interesting than the destination.

# Requirements

## Reliability

To start, this will run some light web-based services I intend to touch daily at a low level of usage.
These services won't ruin my day if unavailable, but it would be nice if I don't have to think about them going down often.

One of the first services I set up was [Miniflux](https://miniflux.app/) for reading RSS feeds.
I use this multiple times per day to read articles.
It pulls a number of feeds throughout the day, but it should be able to catch up on them without breaking a sweat if it is down for a day.

When updating these services, it's completely acceptable for them to be down during updates, since I'm the only user.
I may use this to host stateless hobby projects that are exposed to the public Internet, but I’ll cross that bridge when I get there.

## Durability

I will start by storing some low-risk persistent data, such as RSS feeds in Miniflux and tasks in [Taskwarrior](https://taskwarrior.org/).
Once I gain confidence in a backup and recovery solution, I’d like to use the platform for personal cloud storage to replace my current usage of Dropbox.
I’m not yet sure what these solutions will look like, but durable personal file storage is the long-term goal.

## Incremental Scaling

Perhaps the biggest selling point of Kubernetes is its ability to scale as much as your wallet can scale.
As I host more services on this platform, I want add compute resources for them to utilize by simply increasing my cloud bill, without significant changes to my infrastructure as code or architecture.
The [Kubernetes scheduler](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/) should make this a breeze.
Due to the trivial scale of this platform, I don’t expect to utilize any dynamic scaling features at the cloud provider or Kubernetes level.

Starting out, I would like to keep my bill under $50 per month.
Once I start running enough services to require multiple data plane nodes and take regular backups of persistent data, I expect to hit about $100 per month.
At maximum scale, I’d prefer not to exceed that.

## Infrastructure as Code

I intend to make use of infrastructure as code (IaC) tooling as much as possible.
In general, I want to adhere to the principles of [immutable infrastructure](https://www.digitalocean.com/community/tutorials/what-is-immutable-infrastructure).
Interactive configuration through tools like SSH should not occur.
All configuration and stateless components should be able to be reproduced using IaC.

When it comes to hobby projects, I'm really bad at writing things down and remembering what I did to a server even a few months ago, so it’s crucial for my repo to reflect what is actually deployed.
Terraform and Kubernetes manifests encourage this [GitOps](https://www.gitops.tech/) principle.
At first, I will use Terraform to deploy manifests to the Kubernetes clusters, but I haven't yet settled on tooling for when the cluster outgrows that approach.
There might also be manual steps to calling the IaC properly and building Docker images, but as time goes on I'd like to automate as much as possible.

## Open Source

With the exception of leveraging a public cloud provider to manage hardware, networking, and a Kubernetes control plane, I will reach for open source software as often as possible.
I'd like to limit usage of cloud providers' proprietary abstractions.
For example, I will stay away from services with highly vendor-specifc APIs like AWS Lambda.
This is always a balancing act, though.
I will use tools that are relatively standard across all public clouds like object storage, a managed Kubernetes control plane, and block storage.

Ultimately, I'd like to use this project to demonstrate the wide range of problems self-hosting open source software can solve.

# Initializing the Cluster

I chose Linode as my cloud provider due to its relatively low cost and simplicity. To get the ball rolling, I set up the Linode Terraform provider in a fresh repo:

``` terraform
# main.tf
terraform {
  backend "s3" {
    bucket = "bgottlob-terraform-state"
    key = "personal-cloud.tfstate"
    region = "us-east-1"
    endpoint = "us-east-1.linodeobjects.com"
    skip_credentials_validation = true
  }

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "1.29.4"
    }
  }
}
```

Before running `terraform init`, I [enabled Linode object storage](https://www.linode.com/docs/products/storage/object-storage/get-started/#enable-object-storage), manually created the `bgottlob-terraform-state` bucket, then generated an access key pair with read/write permissions on that bucket.
I then set the environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` with the access and secret keys of the generated key pair.
Linode object storage is S3-compatible, but regardless, the [`s3` Terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3) expects `AWS` prefixed environment variables.
Next, I created a [Linode API personal access token](https://www.linode.com/docs/products/tools/api/get-started/#get-an-access-token) and set it to the environment variable `LINODE_TOKEN`, which is used by the [Linode Terraform provider](https://registry.terraform.io/providers/linode/linode/latest/docs) to manage resources.

After running `terraform init`, setting up a cluster was as easy as writing these 14 lines and running `terraform apply`:

``` terraform
# main.tf
resource "linode_lke_cluster" "personal" {
  label = "bgottlob-personal"
  k8s_version = "1.25"
  region = "us-east"

  control_plane {
    high_availability = false
  }

  pool {
    type = "g6-standard-1"
    count = 1
  }
}
```

I created a pool with one humble node and turned off the high availability control plane.
It was a bit irritating to figure out what string to use for the instance type.
I found the easiest way was to run the following query to the Linode API, then browse the JSON response to figure out what the smallest instance type was:

``` bash
curl 'https://api.linode.com/v4/linode/types' > instance_types.json
```
Through trial and error, I found out that Nanodes cannot be used in Kubernetes clusters, making `g6-standard-1` the cheapest option, a shared VM boasting 2 GB of memory and 1 vCPU.

From here, the Linode console provided me with a download link for my cluster’s kubeconfig file.
Once I placed that in `~/.kube/config`, I was set up to run `kubectl` commands against my cluster. 

At this point, my cloud bill looked something like this, adjusting for the [April 2023 Linode rate increase](https://www.linode.com/blog/linode/akamai_cloud_computing_price_update/):

* [Linode Kubernetes Engine](https://www.linode.com/pricing/#kubernetes) (cost of the one node): $12 per month
* [Object Storage](https://www.linode.com/pricing/#object-storage) (first 250 GB): $5 per month

$5 is pretty steep just for storing a Terraform state file, but I’ll soon be storing Docker images here as well.
Besides, this was money well-spent first time I switched from working on my desktop to my laptop.

[Stay tuned via RSS](/index.xml) for more developments!
