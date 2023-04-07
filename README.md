# Description
this is a sample ECS ci/cd pipeline

infra/ contains aws terraform script and task definition for ECS

service/ has the implementation code for the service

# TODOs
- run two separate pipelines for infra/ and service/ folders
- add ALB in front of ASG
- use tfvars
- read iam credentials from environment variables (store them in github actions secrets)

