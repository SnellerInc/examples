---
title: Sneller Cloud Onboarding using Terraform
toc: true
search: docs
---
## Find scripts on GitHub
You can also find all the scripts in the
[https://github.com/SnellerInc/examples/tree/master/terraform/cloud-onboarding](https://github.com/SnellerInc/examples/tree/master/terraform/cloud-onboarding) repository.

## Details on Terraform 

The Terraform provider requires the token that has been created in the
console.

This script uses the following variables:
 * `region` specifies the AWS region where to deploy the cluster. Make sure
   that you specify a region that also supports Sneller (`us-east-1` is a
   safe choice).
 * `sneller_token` specifies the Sneller token that is used to authenticate
   with Sneller. If the token isn't valid (or has expired), then a new
   token can be created in the Sneller web-console.
 * `prefix` specifies a prefix that is used for all global resources. Some
   resources need unique names (i.e. S3 buckets). If you don't specify a
   prefix, then it will generate a random 4 character prefix instead.
 * `database` / `table` specifies the name of the example database and
   table that is created during deployment.

{{<include file="main.tf" format="terraform" >}}

To ensure that we always have a prefix, we need some "magic" to create a
randomized prefix if no prefix was set. Note that Terraform also stores the
random prefix in the state, so it won't change between runs.

{{<include file="prefix.tf" format="terraform" >}}

### Creating the S3 buckets
Sneller uses two kinds of buckets:

1. Source buckets that hold the data that will be ingested.
   The data can either stay in these buckets or it can be removed after
   ingestion.
2. Ingestion bucket that holds the data that has been ingested by Sneller.
   The query engine always uses this data, so make sure it isn't deleted
   (it's not a cache). You can always export data back to the original
   JSON format.

### Source bucket
First we'll create the source bucket and make sure public access is
denied. In this example we'll also add some (small) sample data to
ensure that we have some sample data by adding three ND-JSON encoded
files to the bucket.

{{<include file="s3-source.tf" format="terraform" >}}

These are the three ND-JSON encoded data files:

{{<include file="sample_data/test1.ndjson" format="json" >}} 
{{<include file="sample_data/test2.ndjson" format="json" >}}
{{<include file="sample_data/test3.ndjson" format="json" >}}

Later in this walkthrough, we'll show you how to ingest your own
(existing) data into Sneller.

### Ingestion bucket
The ingestion bucket should also disallow public access. It holds the
[table definition files](../table-definition) and the actual ingested
data.

{{<include file="s3-ingest.tf" format="terraform" >}}

## Setup the Sneller IAM role
Sneller Cloud doesn't store your data. All data will *always* be
persisted in your own account and we will never persist your data
(although it may be cached in RAM for performance reasons). We
do need to read the source data and take care of your ingestion
bucket.

To allow Sneller to work in these buckets, a custom IAM role should
be defined in your AWS account and Sneller should be allowed to
assume that role. Sneller creates an internal custom IAM role in
our account for each tenant that will be used to assume your role.

Sneller creates a per-tenant IAM role to deal with the
[confused deputy problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html).
AWS also has its own solution for this, called
[external ID](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html).
Sneller also supports the use of the external ID and it's also used
in the next example.

The following script creates an IAM role that:
* Can be assumed by the internal Sneller IAM role when the
  correct external ID is passed.
* Allows read-only access in the source bucket.
* Allows read/write access in the ingestion bucket (only for
  objects starting with the `db/` prefix). 

Terraform will take care of creating a 12-character unique string
that is used as the external ID.

{{<include file="iam-role.tf" format="terraform" >}}

Note that the
[`sneller_tenant`](https://registry.terraform.io/providers/SnellerInc/sneller/latest/docs/data-sources/tenant)
data-source is used to obtain the IAM role ARN that Sneller uses
to assume your role.

## Register the bucket and IAM role with Sneller Cloud
Sneller should know where to look for the databases in your account and
which IAM role to assume to access it. This can be configured using the
[`sneller_tenant_region`](https://registry.terraform.io/providers/SnellerInc/sneller/latest/docs/resources/tenant_region)
resource.

It specifies both the ingestion bucket and the IAM role that has been
created in the previous step.

{{<include file="sneller-tenant-region.tf" format="terraform" >}}

Note that this resource depends on the IAM role policy attachment,
because Sneller can't validate access before the IAM role has been
given this permission. When this dependency is not met, then Terraform
may already register the bucket without Sneller being able to validate
access. This would cause a failure, although it will probably succeed
the next time you apply the script. This dependency is added to prevent
this first failure.

## Register table
Sneller now knows where to look for table definitions, but we don't have
any tables yet. A table can be added using the
[`sneller_table`](https://registry.terraform.io/providers/SnellerInc/sneller/latest/docs/resources/table)
resource.

This is a very simple table, so we will just point it to the correct
S3 source bucket and path pattern.

{{<include file="sneller-table.tf" format="terraform" >}}

Note that the table definition can only be saved when the ingestion
bucket is known. That's why there is a dependency to the
`sneller_tenant_region.sneller` resource.

## Setting up S3 event notifications

### Source bucket
You can now query the table, but if you add new files to the source bucket
they don't show up in the results. That's because Sneller only ingests new
data when it is asked to do so. The open-source version of Sneller uses
`sdb` that can scans the source bucket again and ingests the new files. This
works fine, but it can result in higher latency when your source bucket
contains a lot of files. Also scanning the bucket isn't free, so it may be
too slow en too expensive when there is a lot of data.

That's why Sneller Cloud also supports an event-based method that relies on
[S3 event notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html).
With the proper configuration, S3 will send a message to a queue whenever
new data is written to the source bucket. Sneller provides an SQS queue, so
the only thing you need to do is to set up the S3 event notifications.

{{<include file="s3-source-events.tf" format="terraform" >}}

### Ingest bucket
Changes can be made to the `definition.json` file that can be managed
either via Terraform or directly in S3. Sneller reads the table definitions
every 5 minutes, but that may be annoying. That's why we also add S3 event
notifications on the ingest bucket. All updates to `definition.json` will
be sent to the ingestion queue and it will invalidate the definitions right
away.

{{<include file="s3-ingest-events.tf" format="terraform" >}}
