
```bash
tofu init


tofu destroy -target="module.base.aws_instance.instance_1" -target="module.base.aws_instance.instance_2"


tofu apply -target="module.base"
tofu apply -target="module.dashboards"
```