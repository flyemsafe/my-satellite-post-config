## Red Hat Virtualization

### Subscriptions

 * [RHV 4.2 1.2. SUBSCRIPTIONS](https://access.redhat.com/documentation/en-us/red_hat_virtualization/4.2/html/release_notes/sect-subscriptions)
 * [Red Hat Hyperconverged Infrastructure for Virtualization 1.5](https://access.redhat.com/documentation/en-us/red_hat_hyperconverged_infrastructure_for_virtualization/1.5/)

**Red Hat Virtualization Manager**

| Subscription Pool | Repo Name   | Repo Label |
|:-------------------|:-----------|:-----------|
|Red Hat Enterprise Linux Server|Red Hat Enterprise Linux Server|rhel-7-server-rpms|
|--|RHEL Server Supplementary|rhel-7-server-supplementary-rpms|
|Red Hat Virtualization|Red Hat Virtualization|rhel-7-server-rhv-4.2-manager-rpms|
|--|Red Hat Virtualization Tools|rhel-7-server-rhv-4-manager-tools-rpms|
|--|Red Hat JBoss Enterprise Application Platform|jb-eap-7-for-rhel-7-server-rpms|
|Red Hat Ansible Engine|Red Hat Ansible Engine|rhel-7-server-ansible-2-rpms|

**Red Hat Virtualization Host**

| Subscription Pool | Repo Name   | Repo Label |
|:-------------------|:-----------|:-----------|
|Red Hat Virtualization|Red Hat Virtualization Host|rhel-7-server-rhvh-4-rpms|


**Red Hat Enterprise Linux 7 Hosts**

| Subscription Pool | Repo Name   | Repo Label |
|:-------------------|:-----------|:-----------|
|Red Hat Enterprise Linux Server|Red Hat Enterprise Linux Server|rhel-7-server-rpms|
|--|Red Hat Enterprise Linux 7 Server - RH Common (v.7 Server for x86_64)|rhel-7-server-rh-common-rpms|
|Red Hat Virtualization|Red Hat Virtualization Management Agents (RPMs)|rhel-7-server-rhv-4-mgmt-agent-rpms|
|Red Hat Ansible Engine|Red Hat Ansible Engine|rhel-7-server-ansible-2-rpms|


**Hosted Engine VM Requires**

```
rhel-7-server-rhv-4.2-manager-rpms
rhel-7-server-rhv-4-manager-tools-rpms
rhel-7-server-rpms
rhel-7-server-supplementary-rpms
jb-eap-7-for-rhel-7-server-rpms
rhel-7-server-ansible-2-rpms
```

**Red Hat Enterprise Linux Host**
When using RHEL as the Hypervisor host, the following repos are required:

```
subscription-manager repos --enable=rhel-7-server-rpms
subscription-manager repos --enable=rhel-7-server-rhv-4-mgmt-agent-rpms
subscription-manager repos --enable=rhel-7-server-ansible-2-rpms
```

**These are the equivalent Satellite Products and Repos**

|Satellite Product|Repository Sets|Repo Label|
|:----------------|:--------------|:---------|
|Red Hat Enterprise Linux Server|Red Hat Enterprise Linux 7 Server (RPMs)|rhel-7-server-rpms|
|--|Red Hat Enterprise Linux 7 Server - Supplementary (RPMs)|rhel-7-server-supplementary-rpms|
|--|Red Hat Enterprise Linux 7 Server - RH Common (RPMs)|rhel-7-server-rh-common-rpms|
|Red Hat Virtualization Manager|Red Hat Virtualization Manager v4.2 RHEL 7 Server RPMs x86_64|rhel-7-server-rhv-4.2-manager-rpms|
|--|Red Hat Virtualization Manager 4 Tools RHEL 7 Server RPMs x86_64|rhel-7-server-rhv-4-manager-tools-rpms|
|JBoss Enterprise Application Platform|JBoss Enterprise Application Platform 7 (RHEL 7 Server) (RPMs)|jb-eap-7-for-rhel-7-server-rpms|
|Red Hat Virtualization|Red Hat Enterprise Virtualization Hypervisor 7 RPMs x86_64 7Server|rhel-7-server-rhevh-rpms|
|--|Red Hat Enterprise Virtualization Management Agents for RHEL 7 RPMs x86_64 7Server|rhel-7-server-rhv-4-mgmt-agent-rpms|
|Red Hat Ansible Engine|Red Hat Ansible Engine 2 RPMs for Red Hat Enterprise Linux 7 Server x86_64'|rhel-7-server-ansible-2-rpms|

#### Enable RHV Satellite Repos

* List a product repository sets

```
hammer repository-set list --product "Red Hat Enterprise Linux Server" --organization $ORG
```

* List available repositories for a repository set

```
hammer repository-set available-repositories --product "JBoss Enterprise Application Platform" --organization $ORG --id 4474

hammer repository-set available-repositories --product "JBoss Enterprise Application Platform" --organization $ORG --name "JBoss Enterprise Application Platform 7 (RHEL 7 Server) (RPMs)"

```

* Enable RHV Repositories

```
hammer repository-set enable --organization "$ORG" --product 'JBoss Enterprise Application Platform' --basearch='x86_64' --releasever='7Server' --name 'JBoss Enterprise Application Platform 7 (RHEL 7 Server) (RPMs)'

hammer repository-set enable --organization "$ORG" --product 'Red Hat Virtualization Manager' --basearch='x86_64' --name 'Red Hat Virtualization Manager v4.2 (RHEL 7 Server) (RPMs)'

hammer repository-set enable --organization "$ORG" --product 'Red Hat Virtualization Manager' --basearch='x86_64' --name 'Red Hat Virtualization Manager 4 Tools (RHEL 7 Server) (RPMs)'

hammer repository-set enable --organization "$ORG" --product 'Red Hat Virtualization' --basearch='x86_64' --releasever='7Server' --name 'Red Hat Enterprise Virtualization Hypervisor 7 (RPMs)'

hammer repository-set enable --organization "$ORG" --product 'Red Hat Virtualization' --basearch='x86_64' --name 'Red Hat Virtualization Manager 4.2 (RHEL 7 Server) (RPMs)'
```

### Red Hat Virtualization Content Views

#### Create Red Hat Virtualization Manager Content View

* Setup Environmental Variables

```
ARCH="x86_64"
TYPE="app"
PRODUCT="rhvm"
LC_ENVS="Testing Production"
CV="cv-${TYPE}-${PRODUCT}"
```

* Create cv-app-rhvm content view

```
hammer content-view create --name "${CV}" --organization $ORG
```

 * Add Repositories to cv-app-rhvm content view

```
CV_PRODUCT="'Red Hat Virtualization Manager'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Virtualization Manager v4.2 RHEL 7 Server RPMs x86_64'
'Red Hat Virtualization Manager 4 Tools RHEL 7 Server RPMs x86_64'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${CV_PRODUCT}" --repository "${repo}"|sh
done < $REPOS
```

 
 * Publish cv-app-rhvm Content Views

```
hammer content-view publish --name "${CV}" --organization $ORG --description "Initial publish"

CVID=$(hammer --csv content-view list --name "${CV}" --organization ${ORG} | grep -vi '^Content View ID,' | awk -F',' '{print $1}')
APP_CVID=`get_latest_version "${CV}"`

hammer content-view version promote --content-view-id $CVID \
--organization "$ORG" \
--to-lifecycle-environment Testing \
--id $APP_CVID \
--async

hammer content-view version promote --content-view-id $CVID \
--organization "$ORG" \
--to-lifecycle-environment Production \
--id $APP_CVID \
--async
```

#### Create Red Hat Virtualization RHEL Host Content View

* Setup Environmental Variables

```
ARCH="x86_64"
TYPE="app"
PRODUCT="rhvrhel"
LC_ENVS="Testing Production"
CV="cv-${TYPE}-${PRODUCT}"
```

* Create cv-app-rhvm content view

```
hammer content-view create --name "${CV}" --organization $ORG
```

 * Add Repositories to cv-app-rhvm content view

```
CV_PRODUCT="'Red Hat Virtualization'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Virtualization 4 Management Agents for RHEL 7 RPMs x86_64 7Server'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${CV_PRODUCT}" --repository "${repo}"|sh
done < $REPOS
```

 
 * Publish cv-app-rhvm Content Views

```
hammer content-view publish --name "${CV}" --organization $ORG --description "Initial publish"

CVID=$(hammer --csv content-view list --name "${CV}" --organization ${ORG} | grep -vi '^Content View ID,' | awk -F',' '{print $1}')
APP_CVID=`get_latest_version "${CV}"`

hammer content-view version promote --content-view-id $CVID \
--organization "$ORG" \
--to-lifecycle-environment Testing \
--id $APP_CVID \
--async

hammer content-view version promote --content-view-id $CVID \
--organization "$ORG" \
--to-lifecycle-environment Production \
--id $APP_CVID \
--async
```



#### Red Hat Virtualization Manager Composite Content View

* Environment Variables

```
ARCH="x86_64"
TYPE="infra"
PRODUCT="rhvm"
LC_ENVS="Testing Production"
ROLE="${TYPE}-${PRODUCT}-server"
CCV="ccv-${ROLE}"
```

* Get subscription ids

This requires the subscription name as the first paramater. You can specefy a optional second paramater the, QTY, this will return the ID for the sub.

```
find_subscription 'Red Hat Enterprise Linux Server with Smart Management, Premium (Physical or Virtual Nodes)' 100

find_subscription 'Red Hat Virtualization Manager' 20
```

* Variable with subscription IDs

```
SubIDs='66 141'
```

* Get the latest version of all required content views

```
composite_cv='cv-os-rhel-7Server cv-app-ansible cv-app-eap cv-app-rhvm'
result=$(for cv in $(echo $composite_cv); do get_latest_version $cv; done)
CV_IDS=$(echo $result | sed -e "s/ /,/g")
```

* Create composite content view

```
echo hammer content-view create --name "$CCV" \
--composite --description "'CCV Role for $PRODUCT'" \
--organization $ORG --component-ids $CV_IDS|sh
```

* Publish content view

```
hammer content-view publish --name "$CCV" \
--organization "$ORG"

VID=`get_latest_version $CCV`

echo hammer content-view version promote --organization "$ORG" \
--content-view "$CCV" \
--to-lifecycle-environment Testing \
--id $VID

VID=`get_latest_version ccv-infra-capsule`
echo hammer content-view version promote --organization "$ORG" \
--content-view "$CCV" \
--to-lifecycle-environment Production \
--id $VID
```

* Create Activation Keys

```
activation_key
REPOS="$(mktemp)"
cat > $REPOS << EOF
rhel-7-server-rhv-4.2-manager-rpms
rhel-7-server-rhv-4-manager-tools-rpms
rhel-7-server-rpms
rhel-7-server-supplementary-rpms
jb-eap-7-for-rhel-7-server-rpms
rhel-7-server-ansible-2-rpms
EOF

create_activation_keys
```

#### Create Red Hat Enterprise Linux RHHI Host Composite Content View


 * Get subscription ids

```
find_subscription 'Red Hat Enterprise Linux Server with Smart Management, Premium (Physical or Virtual Nodes)' 100
find_subscription 'Red Hat Virtualization (2-sockets), Premium' 25
find_subscription 'Red Hat Gluster Storage , Premium (1 Node)' 25
```

 * Setup Environment Variables

```
ARCH="x86_64"
TYPE="infra"
PRODUCT="rhhihost"
LC_ENVS="Testing Production"
ROLE="${TYPE}-${PRODUCT}-server"
CCV="ccv-${ROLE}"
SubIDs='66 36 121'
composite_cv='cv-os-rhel-7Server cv-app-gluster cv-app-rhvrhel cv-app-ansible'
```

 * Get the latest versions of all required content views

```
result=$(for cv in $(echo $composite_cv); do get_latest_version $cv; done)
CV_IDS=$(echo $result | sed -e "s/ /,/g")
```

* Create composite content view

```
echo hammer content-view create --name "$CCV" \
--composite --description "'CCV Role for $PRODUCT'" \
--organization $ORG --component-ids $CV_IDS|sh
```

* Publish content view

```
hammer content-view publish --name "$CCV" \
--organization "$ORG"

VID=`get_latest_version $CCV`

echo hammer content-view version promote --organization "$ORG" \
--content-view "$CCV" \
--to-lifecycle-environment Testing \
--id $VID|sh

VID=`get_latest_version ccv-infra-capsule`
echo hammer content-view version promote --organization "$ORG" \
--content-view "$CCV" \
--to-lifecycle-environment Production \
--id $VID|sh
```

 * Activation Key

```
REPOS="$(mktemp)"
cat > $REPOS << EOF
rhel-7-server-satellite-tools-6.4-rpms
rhel-7-server-optional-rpms
rhel-7-server-rhv-4-mgmt-agent-rpms
rhel-7-server-ansible-2-rpms
rhel-7-server-rpms
rhel-7-server-supplementary-rpms
rhel-7-server-extras-rpms
rh-gluster-3-for-rhel-7-server-rpms
EOF

create_activation_keys
```

