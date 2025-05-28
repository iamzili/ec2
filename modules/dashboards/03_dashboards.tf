variable "instance_ids" {
  description = "List of EC2 instance IDs from first module"
  type        = list(string)
}

locals {
  instance_ids = var.instance_ids  # Use variable instead of direct resource reference
}

# data source to get instance information
data "aws_instance" "instances" {
  for_each    = toset(local.instance_ids)
  instance_id = each.value
}

variable "network_interfaces" {
  description = "List of network interfaces"
  type        = list(string)
  default     = ["ens5"]
}

variable "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  type        = string
  default     = "ENA-Metrics-Dashboard"
}

resource "terraform_data" "trigger_by_timestamp" {
  input = timestamp()
}

locals {
  # Create metrics for each instance
  ena_metrics = {
    bw_in_allowance_exceeded      = "ethtool_bw_in_allowance_exceeded"
    bw_out_allowance_exceeded     = "ethtool_bw_out_allowance_exceeded"
    conntrack_allowance_exceeded  = "ethtool_conntrack_allowance_exceeded"
    linklocal_allowance_exceeded  = "ethtool_linklocal_allowance_exceeded"
    pps_allowance_exceeded        = "ethtool_pps_allowance_exceeded"
  }
  
  # generate metric arrays for each metric type
  metric_widgets = [
    for metric_key, metric_name in local.ena_metrics : {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 24
      height = 6
      properties = {
        metrics = concat([
          for instance_id in local.instance_ids : [
            for interface in var.network_interfaces : [
              "CWAgent", metric_name, "driver", "ena", "host", data.aws_instance.instances[instance_id].private_dns, "interface", interface,
              { "label": "${data.aws_instance.instances[instance_id].private_dns} (${interface})" }
            ]
          ]
        ]...)
        period = 60
        stat   = "Sum"
        region = "us-east-1"
        title  = metric_key
        view   = "timeSeries"
        yAxis = {
          left = {
            min = 0
            label = "Count"  # Unit label
            showUnits = false  # This removes the "No Unit" text
          }
        }
      }
    }
  ]
}

resource "aws_cloudwatch_dashboard" "ena_metrics" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = local.metric_widgets
  })

  # the dashboard should be recreated for every change to reflect changes
  lifecycle {
    replace_triggered_by = [terraform_data.trigger_by_timestamp]
  }
}

output "dashboard_url" {
  description = "URL of the created CloudWatch dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.ena_metrics.dashboard_name}"
}
