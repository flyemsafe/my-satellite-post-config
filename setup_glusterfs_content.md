## Gluster

 * Enable Products and Repos

```
hammer repository-set enable --name "Red Hat Gluster Storage 3 Server (RPMs)" --product "Red Hat Gluster Storage Server for On-premise" --organization $ORG --basearch x86_64 --releasever 7Server

hammer repository-set enable --name "Red Hat Gluster Storage 3 Samba (for RHEL 7 Server) (RPMs)" --product "Red Hat Gluster Storage Server for On-premise" --organization $ORG --basearch x86_64 --releasever 7Server

hammer repository-set enable --name "Red Hat Gluster Storage 3 Web Admin Agent (RPMs)" --product "Red Hat Gluster Storage Server for On-premise" --organization $ORG --basearch x86_64 --releasever 7Server

hammer repository-set enable --name "Red Hat Gluster Storage 3 NFS (RPMs)" --product "Red Hat Gluster Storage Server for On-premise" --organization $ORG --basearch x86_64 --releasever 7Server
```

 * Setup Environment Variables

```
ARCH="x86_64"
TYPE="app"
PRODUCT="gluster"
LC_ENVS="Testing Production"
CV="cv-${TYPE}-${PRODUCT}"
CV_PRODUCT="'Red Hat Gluster Storage Server for On-premise'"
```

* Setup Content View with repos

```
hammer content-view create --name "${CV}" --organization $ORG

REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Gluster Storage 3 NFS RPMs x86_64 7Server'
'Red Hat Gluster Storage 3 Samba for RHEL 7 Server RPMs x86_64 7Server'
'Red Hat Gluster Storage 3 Server RPMs x86_64 7Server'
'Red Hat Gluster Storage 3 Web Admin Agent RPMs x86_64 7Server'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${CV_PRODUCT}" --repository "${repo}"|sh
done < $REPOS
```

* Publish and promote content view

```
hammer content-view publish --name "${CV}" --organization $ORG \
    --description "Initial publish"

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

#### Create Gluster Composite View

 * Get subscription ids

```
find_subscription 'Red Hat Enterprise Linux Server with Smart Management, Premium (Physical or Virtual Nodes)' 100

find_subscription 'Red Hat Gluster Storage , Premium (1 Node)' 25
```

 * Setup Environment Variables

```
ARCH="x86_64"
TYPE="infra"
PRODUCT="gluster"
LC_ENVS="Testing Production"
CCV="ccv-${TYPE}-${PRODUCT}"
ROLE="${TYPE}-${PRODUCT}-server"
SubIDs='66 121'
```

 * Get the latest versions of all required content views

```
composite_cv='cv-os-rhel-7Server cv-app-gluster'
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
rhel-7-server-rpms
rhel-7-server-supplementary-rpms
rhel-7-server-extras-rpms
rh-gluster-3-for-rhel-7-server-rpms
EOF

create_activation_keys
```
