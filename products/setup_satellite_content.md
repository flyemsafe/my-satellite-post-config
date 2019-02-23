## Satellite 6

### Capsule Server App Content View

**Setup Environment**

```
ORG=ACME
cv_name=cv-app-capsule
cv_label=cv-app-capsule
cv_description='Satellite 6 Capsule Content View'
```

**Create content view**

```
hammer content-view create --name "cv-app-capsule" --description "Satellite 6 Capsule Content View" --organization "$ORG"
```

#### Add repositories

**Red Hat Satellite Capsule 6.4 for RHEL 7 Server RPMs x86_64**

```
CV_PRODUCT="'Red Hat Satellite Capsule'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Satellite Capsule 6.4 for RHEL 7 Server RPMs x86_64'
EOF

add_cv_repo $cv_name $ORG "$CV_PRODUCT" $REPOS|sh
```

**Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server x86_64 7Server**

```
CV_PRODUCT="'Red Hat Software Collections for RHEL Server'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Software Collections RPMs for Red Hat Enterprise Linux 7 Server x86_64 7Server'
EOF

add_cv_repo $cv_name $ORG "$CV_PRODUCT" $REPOS|sh
```

**Red Hat Satellite Maintenance 6 for RHEL 7 Server RPMs x86_64**

```
CV_PRODUCT="'Red Hat Enterprise Linux Server'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Satellite Maintenance 6 for RHEL 7 Server RPMs x86_64'
EOF

add_cv_repo $cv_name $ORG "$CV_PRODUCT" $REPOS|sh
```

**Red Hat Ansible Engine 2.6 RPMs for Red Hat Enterprise Linux 7 Server x86_64**

```
CV_PRODUCT="'Red Hat Ansible Engine'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Ansible Engine 2.6 RPMs for Red Hat Enterprise Linux 7 Server x86_64'
EOF

add_cv_repo $cv_name $ORG "$CV_PRODUCT" $REPOS|sh
```

**Publish Content View**

```
hammer content-view publish --name "cv-app-capsule" --organization "$ORG"
```

### Capsule Server Role

**Setup Environment**

```
ORG=ACME
cv_name=cv-app-capsule
cv_role_name=ccv-infra-capsule
cv_role_label=ccv-infra-capsule
cv_role_description='CCV for Satellite 6 Capsule'

LC_ENVS="Testing Production"
ACTIVATION_KEYS=$(mktemp)
SubIDs=56
SAT_VER="6.4"
ROLE=infra-capsule
ARCH=x86_64
CV=$cv_role_name
```

**Create ccv-infra-capsule**

```
composite_cv='cv-os-rhel-7Server cv-app-capsule'
result=$(for cv in $(echo $composite_cv); do get_latest_version $cv; done)
CV_IDS=$(echo $result | sed -e "s/ /,/g")

echo hammer content-view create --name "ccv-infra-capsule" \
--composite --description '"CV Role for Satellite 6 Capsule"' \
--organization $ORG --component-ids $CV_IDS
```

**Publish ccv-infra-capsule**

```
hammer content-view publish --name "ccv-infra-capsule" \
--organization "$ORG"

VID=`get_latest_version ccv-infra-capsule`

echo hammer content-view version promote --organization "$ORG" \
--content-view "ccv-infra-capsule" \
--to-lifecycle-environment Testing \
--id $VID --async

VID=`get_latest_version ccv-infra-capsule`
echo hammer content-view version promote --organization "$ORG" \
--content-view "ccv-infra-capsule" \
--to-lifecycle-environment Production \
--id $VID --async
```

#### Create Capsule Activation Keys

```
for LC_ENV in $(echo ${LC_ENVS})
do
LC_ENV_LOWER=$(echo ${LC_ENV} | tr '[[:upper:]' '[[:lower:]]')
LC_ENV_UPPER=$(echo ${LC_ENV} | tr '[[:lower:]' '[[:upper:]]')
ACT_KEY="act-${LC_ENV_LOWER}-${ROLE}-${ARCH}"

grep "$ACT_KEY" $ACTIVATION_KEYS >/dev/null
if [ "$?" -ne "0" ];
then
  echo hammer activation-key create --name "$ACT_KEY" --content-view "$CV" --lifecycle-environment "${LC_ENV}" --organization "${ORG}"|sh
  ACT_KEY_ID=$(hammer activation-key list --name $ACT_KEY --organization $ORG | grep -o "^[0-9].")
fi

for SubID in ${SubIDs}
do
echo hammer activation-key add-subscription --name "$ACT_KEY" --subscription-id "${SubID}" --organization "${ORG}"
done


REPOS="$(mktemp)"
cat > $REPOS << EOF
rhel-7-server-rpms
rhel-7-server-satellite-capsule-${SAT_VER}-rpms
rhel-server-rhscl-7-rpms
rhel-7-server-satellite-maintenance-6-rpms
rhel-7-server-ansible-2.6-rpms
EOF

while read repo;
do
  echo hammer activation-key content-override --id $ACT_KEY_ID --organization "$ORG" \
--content-label "${repo}" --value 1
done < $REPOS
done
```
