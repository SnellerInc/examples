# Table definitions

Here you can find some (template) `definition.json` examples for Sneller:

Examples:
- **aws-cloudtrail-definition.json**: definition for AWS CloudTrail
- **aws-config-definition.json**: definition for AWS Config
- **aws-elb-definition.json**: definition for ELB (Elastic Load Balancer)
- **aws-route53-definition.json**: definition for Route53
- **aws-s3-access-definition.json**: definition for S3 Access
- **aws-s3-inventory-definition.json**: definition for S3 Inventory
- **aws-vpc-flow-logs-definition.json**: definition for AWS VPC Flow Logs
- **aws-waf-definition.json**: definition for AWS WAF (Web Application Firewall)

## Create new table

All (definition) state for a table is stored in a single JSON file in S3. See [here](https://sneller.io/docs/table-definition) for the full specification.

Creating a new table is straightforward:
- create a `definition.json` file and update the `pattern` attribute to point to the correct location in the source bucket
- copy the `definition.json` file to the ingestion bucket under the path `db/<db-name>/<table-name>/`
- If not already configured for another table, enable S3 Event Notifications for the source bucket

That is all there is to it.

## Example

Creating a new table is very simple since it only involves creating a new `definition.json` file in the right location and adding data to the source bucket.

For this example we will be creating a table for the [gharchive](https://gharchive.org) (GitHub archive) data and ingest some data.

**Note**: the code below assumes you have [onboarded onto Sneller Cloud](https://sneller.io/docs/cloud-onboarding) (which just takes a minute using Terraform so setup the correct S3 buckets and IAM permissions etc.):

### Add table definition

You can simply create the `definition.json` like this and copy it into the S3 ingestion bucket:
```sh
export SNELLER_SOURCE=$(terraform output -json sneller_source | jq -r '.')
export SNELLER_INGEST=$(terraform output -json sneller_ingest | jq -r '.')
cat > definition.json <<EOF
{
  "input": [
    {
      "pattern": "s3://$SNELLER_SOURCE/gharchive/*.json.gz",
      "format": "json.gz"
    }
  ]
}
EOF
aws s3 cp definition.json s3://$SNELLER_INGEST/db/demo/gharchive/
```

Note: the `pattern` in the `definition.json` file refers to the _source_ bucket whereas the `definition.json` itself goes into the _ingestion_ bucket.

### Add some data

Simply copy some data into the source bucket at the correct path to add it to the `gharchive` table:
```sh
wget https://data.gharchive.org/2015-01-01-{15..16}.json.gz
aws s3 mv 2015-01-01-15.json.gz s3://$SNELLER_SOURCE/gharchive/
aws s3 mv 2015-01-01-16.json.gz s3://$SNELLER_SOURCE/gharchive/
```

### Query the table

Now you can simply query the `gharchive` table (from the `demo` database):
```sh
curl -H "Authorization: Bearer $SNELLER_TOKEN" \
     -H "Accept: application/json" \
     -s "$SNELLER_ENDPOINT/query?database=demo" \
     --data-raw "SELECT COUNT(*) FROM gharchive"
```
