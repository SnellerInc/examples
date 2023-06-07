---
title: Ingest CloudTrail logging (Terraform setup)
toc: true
search: docs
---
## Prerequisites
Before ingesting CloudTrail logging in this script, make sure:
1. You should already have credentials to access your AWS account.
1. You registered with Sneller Cloud and you have a bearer token.
1. You setup Sneller with a proper ingestion bucket and IAM roles.

If you followed the [cloud onboarding](../cloud-onboarding), then you
should be fine. You can download the Terraform scripts as follows:
```sh
git clone https://github.com/snellerinc/examples 
cd examples/terraform/ingest-cloudtrail
```

All examples are written for Linux and should also work on MacOS. All
examples have also been tested in WSL2 (Windows Subsystem for Linux).

## Summary
The scripts have been written to work with the onboarding scripts, so
you should be able to run the scripts like this:
```sh
export TF_VAR_sneller_token=<your-bearer-token>
terraform init   # only needed once
terraform apply
```

The terraform scripts perform the following tasks:
1. Create an S3 bucket for the CloudTrail logging and allow AWS to store
   logging in it. The script tries to detect the prefix that is used during
   onboarding and will use the same prefix for the CloudTrail logging bucket.
1. Allow the Sneller IAM role to access the bucket with CloudTrail logging for ingestion.
1. Create a table definition (database: `cloudtrail`, table: `cloudtrail`) that ingests
   the CloudTrail logging.

CloudTrail batches the delivery of events, so it may take a while before data
shows up in Sneller. You can browse through the AWS console to make sure that
API calls are invoked on your account.

Now run the following command to determine the number of items per service.
```sh
export SNELLER_TOKEN=<your token here>
export SNELLER_ENDPOINT=https://snellerd-production.<region>.sneller.io
curl -H "Authorization: Bearer $SNELLER_TOKEN" \
      -H "Accept: application/json" \
      -s "$SNELLER_ENDPOINT/query?database=cloudtrail" \
      --data-raw "SELECT eventSource, COUNT(*) FROM cloudtrail GROUP BY eventSource ORDER BY COUNT(*) DESC LIMIT 100"
```

## Details

### Setting up Terraform
These scripts depend on the AWS and Sneller provider. The AWS provider uses the
current user's AWS credentials, so make sure you have sufficient rights.

This script uses the following variables:
 * `region` specifies the AWS region of your Sneller instance
   (default: `us-east-1`).
 * `sneller_token` should hold the Sneller bearer token. If it's not set, then
   Terraform will ask for it.
 * `prefix` specifies a prefix that is used for the S3 bucket name. If you
   don't specify a prefix, then it will try to autodetect the prefix and/or
   create a new random prefix.

{{< include collapsed=true file="main.tf" format="terraform" >}}

The next steps require the SQS queue and IAM role that Sneller uses, so it
should be determined using the `sneller_tenant_region` data source that
provides this information.

{{< include collapsed=true file="sneller-tenant-region.tf" format="terraform" >}}

Some "magic" is used to automatically derive the prefix from the current
Sneller IAM role. When that's not possible, a random prefix will be generated:

{{< include collapsed=true file="prefix.tf" format="terraform" >}}

### S3 bucket for CloudTrail logging
All CloudTrail logging is written into an S3 bucket with the following
characteristics:

 * Disallow public access.
 * Add [bucket policy](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html)
   to allow CloudTrail to write to the bucket. 
 * Add lifecycle event to delete the CloudTrail logging from the S3 bucket
   after 7 days (it will stay in the Sneller table).
 * Add S3 event notification to notify Sneller of new CloudTrail logging
   objects.

{{< include collapsed=true file="s3-cloudtrail.tf" format="terraform" >}}

### Enable IAM role to access CloudTrail logging
The IAM role that is assumed by Sneller to read the source data should be
granted access to the CloudTrail data:

{{< include collapsed=true file="iam-role-cloudtrail-policy.tf" format="terraform" >}}

### Enable CloudTrail logging
The S3 bucket has been set up, so now the actual CloudTrail logging can be
enabled:

{{< include collapsed=true file="cloudtrail.tf" format="terraform" >}}

In this example, *all* service logging in *all* regions will be enabled, but
this can be customized using
[event filtering](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail).

### Sneller table
Everything has now been set up to deliver CloudTrail logging to the S3 bucket,
so we only need to create a table with the proper definition to ingest the
data:

{{< include collapsed=true file="sneller-table.tf" format="terraform" >}}

The table is [partitioned](../partitions) based on the region of the CloudTrail
data. This makes queries on a single region faster and more cost efficient.