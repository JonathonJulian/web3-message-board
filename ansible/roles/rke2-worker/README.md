# RKE2 Worker Role

An Ansible role to add worker nodes to an existing RKE2 Kubernetes cluster.

## Features

- Supports joining worker nodes to an existing RKE2 cluster
- Configures node labels and taints
- Handles all prerequisites (kernel modules, sysctl settings, etc.)
- Security-focused design for token handling
- Idempotent operations - safe to run multiple times

## Requirements

- An existing RKE2 server/control-plane node
- Access to the RKE2 server URL and token
- Ubuntu 20.04+ or other compatible Linux distribution
- Ansible 2.9+

## Role Variables

See `defaults/main.yml` for all configurable variables. Key variables:

| Variable Name | Description | Default Value |
|---------------|-------------|---------------|
| `rke2_server_url` | URL of the RKE2 server to join | `https://rke2-server:9345` |
| `rke2_token` | Token for joining the cluster | *Required* |
| `rke2_worker_version` | RKE2 version to install | `stable` |
| `rke2_worker_node_labels` | List of node labels to apply | `[]` |
| `rke2_worker_node_taints` | List of node taints to apply | `[]` |

## Dependencies

None.

## Example Playbook

```yaml
- hosts: worker_nodes
  become: yes
  vars:
    rke2_server_url: "https://10.0.0.10:9345"
    rke2_token: "{{ lookup('ansible.builtin.env', 'RKE2_TOKEN') }}"
    rke2_worker_node_labels:
      - "node.kubernetes.io/worker=true"
  roles:
    - role: rke2-worker
```

## Secret Management

The role is designed to handle the RKE2 token securely:

1. Store the token in an Ansible Vault or environment variable
2. Pass it to the role via `rke2_token` variable
3. The token is saved securely on the target node with restricted permissions
4. Task that handles the token is set with `no_log: true` to prevent exposure in logs

## License

MIT

## Author Information

Created for Web3 Message Board project.