# servo-k8slive

Optune servo connector for Kubernetes orechestration and optimization of a tuning pod

Unlike most connectors, servo-k8slive depends on the configuration of servo-k8s (see Configuration section below). The tuning pod will derive the
target deployment (henceforth referred to as the main deployment or main component) from the sole component of the servo-k8s config and uses the
values of its `mem` and `cpu` guard rails to inform the descriptor of the k8s-live component

On describe, this connector initially reports the resource and env configuration of the main component as no tuning pod exists yet. 
On the first adjust that has `deploy_to` set to `tuning` and `replicas` set to 1, the connector will create a tuning pod whose template is copied from
the deployment of the sole component in the servo-k8s config referred to by `main_section` (see config below). The connector adds the label 
`opsani_role: tuning` and annotation `opsani.com/opsani-tuning-for: [MAIN DEPLOYMENT NAME]` and updates its cpu, mem, and environement variables
with the adjustment values sent to the servo-k8slive component

The pods is then deployed with its owner references set to the servo deployment (for simplified cleanup) and the connector waits for the pod and containers
to become ready. Optionally, the connector may enforce a settlement period during which it waits and monitors the pod for instability such as container restarts

## Configuration

NOTE: k8s-live is not compatible with servo-k8s configurations that specify more than one component or adjustments that specify more than 1 replicas 
as they are beyond the scope of k8slive's use case.Such configurations or adjustments will raise an error during connector initialization and adjustment 
respectively.

NOTE: when `selector` is set to both, the connector will report the value from the container requests if they are specified, otherwise it will report the value from limits.
If neither are specified, it reports a value of 0

```yaml
k8s:
  adjust_on: data["control"]["userdata"]["deploy_to"] == "main"
  namespace: app2
  application:
    components:
      web-main/main:
        settings:
          replicas:
            min: 1
            max: 3
          cpu:
            min: 0.125
            max: 2.0
            step: 0.125
          mem:
            min: 0.125
            max: 2.0
            step: 0.125
        env:
          COMMIT_DELAY:
            type: range
            min: 1
            max: 100
            step: 1
            default: 20
k8slive:
  deploy_to: tuning # Optional, default is tuning
  adjust_on: data["control"]["userdata"]["deploy_to"] == "tuning"  # Optional. Legacy deploy_to support, defaults to None
  component: opsani-tuning  # Optional, default: opsani-tuning. Name of the component to be reported to the OCO
  pod_name: opsani-tuning   # Optional, default: opsani-tuning. Name of the tuning pod, override to avoid duplicate(s)
  main_section: k8s         # Optional, default: k8s. Config secion name of the main component
  settlement: 130           # Optional, default: 0. Time in seconds to wait and monitor tuning pod post-adjustment for instability. Overriden by main component settlement config
  on_fail: destroy          # Optional, default: destroy. Action to be taken upon failed adjustment rollout or settlement. Valid values are "destroy" and "nop"
  cpu_selector: both        # Optional, default: both. The resource section to query and adjust for cpu values. valid values: both, limit, request
  mem_selector: both        # Optional, default: both. The resource section to query and adjust for mem values. valid values: both, limit, request

```
