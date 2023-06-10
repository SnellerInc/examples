# Sneller examples

Here you can find some examples for Sneller:
- table definitions (eg. for AWS CloudTrail and VPC Flow Logs)
- terraform scripts (eg. for onboarding onto Sneller Cloud)

## Example

Sneller makes it very easy to create a new table on S3: just create a new `definition.json` file in the ingestion bucket and add some data to the source bucket.

In this example we will be creating a table for the [gharchive](https://gharchive.org) (GitHub archive) data and ingest some data.

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
## License

These examples are released under the Apache 2.0  license. All comments, remarks and pull requests welcome.
