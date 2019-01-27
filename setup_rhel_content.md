

### Variables

```
ORG=ACME
ORG_ID=$(hammer --csv organization list --search $ORG | grep -o [0-9])
```

## Red Hat Enterprise Linux


* Set Environment Variables

```
ARCH="x86_64"
TYPE="os"
LC_ENVS="Testing Production"
ORG=ACME
SAT_VER="6.4"
CV_PRODUCT="rhel"
ROLE="${CV_PRODUCT}-7Server"
CV="cv-${TYPE}-${ROLE}"
PRODUCT='"Red Hat Enterprise Linux Server"'
enabled_products=$(mktemp)
REPOSITORY_SETS=$(mktemp)
releasever="7Server"
```

* Enable Repositories Sets

```
cat > $REPOSITORY_SETS <<EOF
"Red Hat Enterprise Linux 7 Server (Kickstart)"
"Red Hat Enterprise Linux 7 Server (RPMs)"
"Red Hat Enterprise Linux 7 Server - Optional (RPMs)"
"Red Hat Enterprise Linux 7 Server - Extras (RPMs)"
"Red Hat Satellite Tools ${SAT_VER} (for RHEL 7 Server) (RPMs)"
EOF


echo hammer --output json repository-set list --enabled=true --product "$PRODUCT" --organization $ORG|sh | awk '/Name/ {print $0}' > $enabled_products

while read product;
do
  grep "$product" $enabled_products >/dev/null
  if [ "$?" -ne "0" ];
  then
    echo hammer repository-set enable --name "$product" --product "$PRODUCT" --organization $ORG --basearch $ARCH --releasever $releasever
  fi
done<$REPOSITORY_SETS

```

### Create content view cv-os-rhel-7Server

```
DESCRIPTION='"RHEL Server 7 Core Build Content View"'
create_content_view
```

### Add software repositories to cv-os-rhel-7Server

```
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Enterprise Linux 7 Server Kickstart x86_64 7Server'
'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server'
'Red Hat Satellite Tools 6.3 for RHEL 7 Server RPMs x86_64'
'Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${PRODUCT}" --repository "${repo}"|sh
done < $REPOS
```

### Publish cv-os-rhel-7Server Content View

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

APP_CVID=`get_latest_version "${CV}"`
hammer content-view version promote --content-view-id $CVID \
--organization "$ORG" \
--to-lifecycle-environment Production \
--id $APP_CVID \
--async
```

### Create cv-os-rhel-7Server Activation Keys

- ACME Subscriptions Available:
	- Red Hat Enterprise Linux Server with Smart Management & Resilient Storage, Standard (Physical or Virtual Nodes)
	- Red Hat Enterprise Linux Server, Premium (1-2 sockets) (Unlimited guests) with Smart Management
	- Red Hat Enterprise Linux Server, Premium (1-2 sockets) (Unlimited guests) with Smart Management
	- Red Hat Enterprise Linux Server with Smart Management, Premium (Physical or Virtual Nodes)
	- Red Hat Enterprise Linux Server with Smart Management & Resilient Storage, Premium (Physical or Virtual Nodes)
	- Red Hat Enterprise Linux for Virtual Datacenters, Premium
	- Red Hat Enterprise Linux for Virtual Datacenters with Smart Management, Standard
- Corp Available Subscriptions:
	+ Employee SKU
	+ CloudForms Employee Subscription
	+ Red Hat Satellite Employee Subscription

Repository_Sets
 - Red Hat Ansible Engine 2.6 RPMs for Red Hat Enterprise Linux 7 Server

```
PRODUCT_SUBS_LIST=$(mktemp)
hammer --csv --csv-separator '#' subscription list --per-page 9999 --organization ${ORG} > $PRODUCT_SUBS_LIST
```

Get the RHEL sub with qty 100
```
SubRHEL=$(grep 100 $PRODUCT_SUBS_LIST | awk -F'#' '/Red Hat Enterprise Linux Server with Smart Management/ {print $1}')
```

```
#rhel-7-server-optional-rpms

ACTIVATION_KEYS=$(mktemp)
hammer --output json activation-key list --organization "$ORG"| awk '/Name/ {print $0}' > $ACTIVATION_KEYS

for LC_ENV in $(echo ${LC_ENVS})
do
LC_ENV_LOWER=$(echo ${LC_ENV} | tr '[[:upper:]' '[[:lower:]]')
LC_ENV_UPPER=$(echo ${LC_ENV} | tr '[[:lower:]' '[[:upper:]]')
ACT_KEY="act-${LC_ENV_LOWER}-${TYPE}-${ROLE}-${ARCH}"

grep "$ACT_KEY" $ACTIVATION_KEYS >/dev/null
if [ "$?" -ne "0" ];
then
  echo hammer activation-key create --name "$ACT_KEY" --content-view "$CV" --lifecycle-environment "${LC_ENV}" --organization "${ORG}"|sh
  ACT_KEY_ID=$(hammer activation-key list --name $ACT_KEY --organization $ORG | grep -o "^[0-9].")
fi

SubIDs="${SubRHEL}"
for SubID in ${SubIDs}
do
echo echo hammer activation-key add-subscription --name "$ACT_KEY" --subscription-id "${SubID}" --organization "${ORG}"|sh
done


REPOS="$(mktemp)"
cat > $REPOS << EOF
rhel-7-server-satellite-tools-${SAT_VER}-rpms
Red Hat Ansible Engine 2.6 RPMs for Red Hat Enterprise Linux 7 Server
EOF

while read repo;
do
  echo hammer activation-key content-override --id $ACT_KEY_ID --organization "$ORG" \
--content-label "${repo}" --value 1|sh
done < $REPOS
done
```

## Red Hat Enterprise Linux Fast Datapath

* Set Environment Variables

```
ARCH="x86_64"
TYPE="tools"
LC_ENVS="Testing Production"
ORG=ACME
SAT_VER="6.4"
CV_PRODUCT="rhel7-fast-datapath"
ROLE="${CV_PRODUCT}"
CV="cv-${TYPE}-${ROLE}"
PRODUCT='"Red Hat Enterprise Linux Fast Datapath"'
enabled_products=$(mktemp)
REPOSITORY_SETS=$(mktemp)
releasever="7Server"
```

* Enable Products

```
cat > $REPOSITORY_SETS <<EOF
"Red Hat Enterprise Linux Fast Datapath (RHEL 7 Server) (RPMs)"
EOF

echo hammer --output json repository-set list --enabled=true --product "$PRODUCT" --organization $ORG|sh | awk '/Name/ {print $0}' > $enabled_products

while read product;
do
  grep "$product" $enabled_products >/dev/null
  if [ "$?" -ne "0" ];
  then
    echo hammer repository-set enable --name "$product" --product "$PRODUCT" --organization $ORG --basearch $ARCH --releasever $releasever
  fi
done<$REPOSITORY_SETS
```

### Create content 

```
DESCRIPTION='"RHEL Server 7 Fast Datapath"'
create_content_view
```

### Add software repositories 
```
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Enterprise Linux Fast Datapath RHEL 7 Server RPMs x86_64 7Server'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${PRODUCT}" --repository "${repo}"|sh
done < $REPOS
```

### Publish Content View

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

APP_CVID=`get_latest_version "${CV}"`
hammer content-view version promote --content-view-id $CVID \
--organization "$ORG" \
--to-lifecycle-environment Production \
--id $APP_CVID \
--async
```
