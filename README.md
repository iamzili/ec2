This repo serves to provision a VPC, subnets, IGW, NATGW, and two EC2 instances with network observability tools and a dashboard for ENA driver metrics. One EC2 instance serves as a client with lower bandwidth capacity than the other EC2 instance (i.e. the server). This setup can be used to test the maximum bandwidth capacity of the client EC2 instance using `iperf3`.

```bash
tofu init

tofu apply -target="module.base"
tofu apply -target="module.dashboards"

tofu destroy
```