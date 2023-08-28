#!/usr/bin/env bash

source ./openstack_config.txt

cat <<EOF
{
  "os_auth_url": "$OS_AUTH_URL",
  "os_region": "$OS_REGION_NAME",
  "os_user_name": "$OS_USERNAME",
  "os_password": "$OS_PASSWORD",
  "os_user_domain_name": "$OS_USER_DOMAIN_NAME",
  "os_project_domain_id": "$OS_PROJECT_DOMAIN_ID",
  "os_tenant_id": "$OS_PROJECT_ID",
  "os_tenant_name": "$OS_PROJECT_NAME"
}
EOF
