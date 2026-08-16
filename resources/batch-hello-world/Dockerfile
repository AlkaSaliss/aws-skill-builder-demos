FROM amazon/aws-cli:latest

CMD ["s3api", "list-buckets", "--query", "Buckets[].Name", "--output", "table"]
