# tf-ghost-blog-simple

Run Ghost Blog in AWS on ECS, in a simple way (i.e., cheap and not resilient)

This is a self-contained app to self-host on ECS. Goals:

- as cheap as possible
  - no load balancer, no autoscaling (this makes it more tricky in some ways)
  - no NAT Gateway
  - using Fargate Spot when possible
- 99% uptime assuming reasonable load
- leverage CloudFront for cheap bandwidth and reducing load