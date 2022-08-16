#!/usr/bin/env bash

# Reset lab
cd /home/labuser
source ./kong-course-gateway-ops-for-kubernetes/base/reset-lab.sh

# Task: Create New Role my_role and add Permissions
http post kongcluster:30001/rbac/roles name=my_role
http post kongcluster:30001/rbac/roles/my_role/endpoints/ \
  	endpoint=* \
  	workspace=default \
  	actions=*

# Task: Create an RBAC user called 'my-super-admin'
http post kongcluster:30001/rbac/users name=my-super-admin user_token="my_token"

# Task: Verify User and Assign Role
http get kongcluster:30001/rbac/users/my-super-admin/role
http post kongcluster:30001/rbac/users/my-super-admin/roles roles='my_role'

# Task: Assign super-admin Role to my-super-admin
http post kongcluster:30001/rbac/users/my-super-admin/roles roles='super-admin'

# Task: Verify my-super-admin Role 
http get kongcluster:30001/rbac/users/my-super-admin/roles

# Task: Automatically Assign Roles to RBAC user
http post kongcluster:30001/rbac/users \
    name=super-admin \
    user_token="super-admin"
http get kongcluster:30001/rbac/users/super-admin/roles

# Task: Enable RBAC, reducing default cookie_lifetime
cd /home/labuser/kong-course-gateway-ops-for-kubernetes
cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":true,
    "cookie_lifetime":60,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong \
--save-config \
--dry-run=client \
--from-file=admin_gui_session_conf \
-o yaml | \
kubectl apply -f -

sed -i "s/admin_gui_url:.*/admin_gui_url: https:\/\/$KONG_MANAGER_URI/g" ./exercises/rbac/cp-values-rbac.yaml
sed -i "s/admin_api_url:.*/admin_api_url: https:\/\/$KONG_ADMIN_API_URI/g" ./exercises/rbac/cp-values-rbac.yaml
sed -i "s/admin_api_uri:.*/admin_api_uri: $KONG_ADMIN_API_URI/g" ./exercises/rbac/cp-values-rbac.yaml
sed -i "s/proxy_url:.*/proxy_url: https:\/\/$KONG_PROXY_URI/g" ./exercises/rbac/cp-values-rbac.yaml
sed -i "s/portal_api_url:.*/portal_api_url: https:\/\/$KONG_PORTAL_API_URI/g" ./exercises/rbac/cp-values-rbac.yaml
sed -i "s/portal_gui_host:.*/portal_gui_host: $KONG_PORTAL_GUI_HOST/g" ./exercises/rbac/cp-values-rbac.yaml

helm upgrade -f ./exercises/rbac/cp-values-rbac.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

# Task: Revert the cookie_lifetime to 36000 seconds
sed -i "s/\"cookie_lifetime\":60/\"cookie_lifetime\":36000/g" admin_gui_session_conf
kubectl create secret generic kong-session-config -n kong \
--save-config \
--dry-run=client \
--from-file=admin_gui_session_conf \
-o yaml | \
kubectl apply -f -

DELETE_POD=`kubectl get pods --selector=app=kong-kong -n kong -o jsonpath='{.items[*].metadata.name}'`
kubectl delete pod $DELETE_POD -n kong

# Task: Verify Authentication with Admin API
http --headers get kongcluster:30001/services
http --headers get kongcluster:30001/services Kong-Admin-Token:my_token

# Task: Create & verify WorkspaceA & WorkspaceB
http post kongcluster:30001/workspaces name=WorkspaceA Kong-Admin-Token:my_token
http post kongcluster:30001/workspaces name=WorkspaceB Kong-Admin-Token:my_token
http get kongcluster:30001/workspaces Kong-Admin-Token:my_token | jq '.data[].name'

# Task: Create AdminA & AdminB
http post kongcluster:30001/WorkspaceA/rbac/users \
    name=AdminA \
    user_token=AdminA_token \
    Kong-Admin-Token:super-admin
http post kongcluster:30001/WorkspaceB/rbac/users \
    name=AdminB \
    user_token=AdminB_token \
    Kong-Admin-Token:super-admin

# Task: Verify AdminA & AdminB
http get kongcluster:30001/WorkspaceA/rbac/users Kong-Admin-Token:super-admin
http get kongcluster:30001/WorkspaceB/rbac/users Kong-Admin-Token:super-admin

# Task: Create an admin role & permissions for WorkspaceA
http post kongcluster:30001/WorkspaceA/rbac/roles name=admin Kong-Admin-Token:super-admin
http post kongcluster:30001/WorkspaceA/rbac/roles/admin/endpoints/ \
  	endpoint=* \
  	workspace=WorkspaceA \
  	actions=* \
  	Kong-Admin-Token:super-admin

# Task: Repeat admin role & permissions for WorkspaceB
http post kongcluster:30001/WorkspaceB/rbac/roles name=admin Kong-Admin-Token:super-admin
http post kongcluster:30001/WorkspaceB/rbac/roles/admin/endpoints/ \
  	endpoint=* \
  	workspace=WorkspaceB \
  	actions=* \
  	Kong-Admin-Token:super-admin

# Task: Assign admin role to admin user in each workspace
http post kongcluster:30001/WorkspaceA/rbac/users/AdminA/roles/ \
    roles=admin \
    Kong-Admin-Token:super-admin
http post kongcluster:30001/WorkspaceB/rbac/users/AdminB/roles/ \
    roles=admin \
    Kong-Admin-Token:super-admin

# Task: Verify AdminA/AdminB access to corresponding Workspaces
http get kongcluster:30001/WorkspaceA/rbac/users Kong-Admin-Token:AdminA_token
http get kongcluster:30001/WorkspaceB/rbac/users Kong-Admin-Token:AdminA_token
http get kongcluster:30001/WorkspaceB/rbac/users Kong-Admin-Token:AdminB_token
http get kongcluster:30001/WorkspaceA/rbac/users Kong-Admin-Token:AdminB_token

# Task: Deploy a service to WorkspaceA with correct Admin
http post kongcluster:30001/WorkspaceA/services name=httpbin_service \
    url=http://httpbin:80 Kong-Admin-Token:AdminB_token
http post kongcluster:30001/WorkspaceA/services name=httpbin_service \
    url=http://httpbin:80 Kong-Admin-Token:AdminA_token
http -f post kongcluster:30001/WorkspaceA/services/httpbin_service/routes name=httpbin \
    hosts=httpbin:80 paths=/httpbin Kong-Admin-Token:AdminA_token

# Task: Verify service in WorkspaceA
http get kongcluster:30001/WorkspaceA/services Kong-Admin-Token:AdminA_token

# Task: Add TeamA_engineer & TeamB_engineer to the workspace teams
http post kongcluster:30001/WorkspaceA/rbac/users name=TeamA_engineer user_token=teama_engineer_user_token Kong-Admin-Token:AdminB_token
http post kongcluster:30001/WorkspaceA/rbac/users name=TeamA_engineer user_token=teama_engineer_user_token Kong-Admin-Token:AdminA_token
http post kongcluster:30001/WorkspaceB/rbac/users name=TeamB_engineer user_token=teamb_engineer_user_token Kong-Admin-Token:AdminB_token

# Task: Create read-only roles and permissions for 'Team_engineer'
http post kongcluster:30001/WorkspaceA/rbac/roles name=engineer-role Kong-Admin-Token:super-admin
http post kongcluster:30001/WorkspaceB/rbac/roles name=engineer-role Kong-Admin-Token:super-admin
http post kongcluster:30001/WorkspaceA/rbac/roles/engineer-role/endpoints/ \
  	endpoint=* \
  	workspace=WorkspaceA \
  	actions="read" \
  	Kong-Admin-Token:AdminA_token
http post kongcluster:30001/WorkspaceB/rbac/roles/engineer-role/endpoints/ \
  	endpoint=* \
  	workspace=WorkspaceB \
  	actions="read" \
  	Kong-Admin-Token:AdminB_token
http post kongcluster:30001/WorkspaceA/rbac/users/TeamA_engineer/roles \
    roles=engineer-role \
    Kong-Admin-Token:AdminA_token
http post kongcluster:30001/WorkspaceB/rbac/users/TeamB_engineer/roles \
    roles=engineer-role \
    Kong-Admin-Token:AdminB_token

# Task: Test read only access for the engineers for their workspace only
http get kongcluster:30001/WorkspaceA/consumers Kong-Admin-Token:teama_engineer_user_token
http post kongcluster:30001/WorkspaceA/consumers username=Jane Kong-Admin-Token:teama_engineer_user_token
http get kongcluster:30001/WorkspaceB/consumers Kong-Admin-Token:teama_engineer_user_token

# Task: Disable RBAC
cat << EOF > admin_gui_session_conf
{
    "cookie_name":"admin_session",
    "cookie_samesite":"off",
    "secret":"kong",
    "cookie_secure":false,
    "storage":"kong"
}
EOF
kubectl create secret generic kong-session-config -n kong \
--save-config \
--dry-run=client \
--from-file=admin_gui_session_conf \
-o yaml | \
kubectl apply -f -
helm upgrade -f ./base/cp-values.yaml kong kong/kong -n kong \
--set manager.ingress.hostname=$KONG_MANAGER_URI \
--set portal.ingress.hostname=$KONG_PORTAL_GUI_HOST \
--set admin.ingress.hostname=$KONG_ADMIN_API_URI \
--set portalapi.ingress.hostname=$KONG_PORTAL_API_URI

# Task: Deploy NetworkPolicy
kubectl apply -f exercises/network-policy/admin-api-restrict.yaml

# Task: Verify restrictions and Delete NetworkPolicy
http $KONG_ADMIN_API_URL
http kongcluster:30001
kubectl delete networkpolicy admin-api-restrict -n kong
