#!/bin/bash

## Sets up Red Hat Enterprise Linux repository sets, create a rhel content view and associated activation key

# User provided variables
ORG=ACME
ARCH="x86_64"
LC_ENVS="Testing Production"
SAT_VER="6.5"
ANSIBLE_VER="2.6"
CV_PRODUCT="rhel"
releasever="7Server"
CV_DESCRIPTION='"RHEL Server 7 Core Build Content View"'

# Required Variables and Functions
TYPE="os"
CV="cv-${TYPE}-${ROLE}"
ROLE=$(echo ${CV_PRODUCT}-${releasever} | tr '[:upper:]' '[:lower:]')
ORG_ID=$(hammer --csv organization list --search $ORG | grep -o [0-9])
enabled_products=$(mktemp)
REPOSITORY_SETS=$(mktemp)
source ./hammer_helper_functions.sh

# Enable Repositories Sets
PRODUCT='"Red Hat Enterprise Linux Server"'
cat > $REPOSITORY_SETS <<EOF
"Red Hat Enterprise Linux 7 Server (Kickstart)"
"Red Hat Enterprise Linux 7 Server (RPMs)"
"Red Hat Enterprise Linux 7 Server - Optional (RPMs)"
"Red Hat Enterprise Linux 7 Server - Extras (RPMs)"
"Red Hat Satellite Tools ${SAT_VER} (for RHEL 7 Server) (RPMs)"
EOF

# Get list of products already enabled
echo hammer --output json repository-set list --enabled=true --product "$PRODUCT" --organization $ORG|sh | awk '/Name/ {print $0}' > $enabled_products

# Enabled products not already enabled
while read product;
do
  grep "$product" $enabled_products >/dev/null
  if [ "$?" -ne "0" ];
  then
    echo hammer repository-set enable --name "$product" --product "$PRODUCT" --organization $ORG --basearch $ARCH --releasever $releasever|sh
  fi
done<$REPOSITORY_SETS

# Create content view cv-os-rhel-7server
create_content_view

# Add software repositories to cv-os-rhel-7Server
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Enterprise Linux 7 Server Kickstart x86_64 7Server'
'Red Hat Enterprise Linux 7 Server RPMs x86_64 7Server'
'Red Hat Satellite Tools ${SAT_VER} for RHEL 7 Server RPMs x86_64'
'Red Hat Enterprise Linux 7 Server - RH Common RPMs x86_64 7Server'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${PRODUCT}" --repository "${repo}"|sh
done < $REPOS

# Publish cv-os-rhel-7Server Content View
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

# Activation Keys
PRODUCT_SUBS_LIST=$(mktemp)
hammer --csv --csv-separator '#' subscription list --per-page 9999 --organization ${ORG} > $PRODUCT_SUBS_LIST

#Get the RHEL sub with qty 100
SubRHEL=$(grep 100 $PRODUCT_SUBS_LIST | awk -F'#' '/Red Hat Enterprise Linux Server with Smart Management/ {print $1}')
ACTIVATION_KEYS=$(mktemp)
hammer --output json activation-key list --organization "$ORG"| awk '/Name/ {print $0}' > $ACTIVATION_KEYS

# Create activation keys
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

# Add subscriptions to activation key
SubIDs="${SubRHEL}"
for SubID in ${SubIDs}
do
echo echo hammer activation-key add-subscription --name "$ACT_KEY" --subscription-id "${SubID}" --organization "${ORG}"|sh
done

# Ensure these repos are enabled
REPOS="$(mktemp)"
cat > $REPOS << EOF
rhel-7-server-satellite-tools-${SAT_VER}-rpms
Red Hat Ansible Engine ${ANSIBLE_VER} RPMs for Red Hat Enterprise Linux 7 Server
EOF

while read repo;
do
  echo hammer activation-key content-override --id $ACT_KEY_ID --organization "$ORG" \
--content-label "${repo}" --value 1|sh
done < $REPOS
done

exit 0