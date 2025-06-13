# 500 - Monitoring Setup

This playbook configures monitoring for the Katana Proxmox server.

## Features

- **Telegraf Agent**: Deploys and configures Telegraf to collect system metrics.
  - **lm-sensors**: Collects hardware sensor data (temperatures, fan speeds, etc.) via the `[[inputs.sensors]]` Telegraf plugin.
- **Proxmox VE Metrics**: Configures Proxmox VE to send its internal metrics directly to InfluxDB.
- **InfluxDB Integration**: All collected metrics are sent to an InfluxDB v2 instance. Credentials and connection details are managed via Ansible Vault.

## Prerequisites

- An InfluxDB v2.x instance must be accessible from the Proxmox server.
- InfluxDB connection details (URL, token, organization, and bucket names) must be defined in `500-monitoring/vault/influxdb.yml` and encrypted using Ansible Vault. Refer to `500-monitoring/vault/influxdb.example.yml` for the required structure.
  - `influxdb_bucket_lm_sensors`: Bucket for Telegraf/lm-sensors data.
  - `influxdb_bucket_proxmox`: Bucket for Proxmox VE's own metrics.

## How to Run

1.  Ensure your `500-monitoring/vault/influxdb.yml` is correctly populated with your InfluxDB details and encrypted.
2.  Navigate to the `500-monitoring` directory.
3.  Run the playbook. You will be prompted for the vault password if not using a password file:
    ```bash
    ansible-playbook playbook.yml --ask-vault-pass
    ```
    Alternatively, if you have `ANSIBLE_VAULT_PASSWORD_FILE` set or use a local `ansible.cfg` pointing to a vault password file:
    ```bash
    ansible-playbook playbook.yml
    ```
