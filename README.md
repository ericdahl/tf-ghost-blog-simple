# tf-ghost-blog-simple

Run Ghost Blog in AWS on ECS, in a simple way (i.e., cheap and not resilient)

This is a self-contained app to self-host on ECS. Goals:

- as cheap as possible
  - no load balancer, no autoscaling (this makes it more tricky in some ways)
  - no NAT Gateway
  - using Fargate Spot when possible
- 99% uptime assuming reasonable load
- leverage CloudFront for cheap bandwidth and reducing load

## Notes
- CloudFront can't point to IP directly
- Ghost has issues with running on port < 1024 on fargate?
- ECS Service Discovery requires using private IPs even if in public zone

## TODO

- fix lambda logic for r53 querying - just query EC2 ENIs direct?
- fargate spot
- EFS?
- ECS service discovery for DNS?
- doesn't work if port < 1024?