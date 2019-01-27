## Red Hat Ansible Engine

* Setup Variables

```
ARCH="x86_64"
TYPE="app"
PRODUCT="ansible"
LC_ENVS="Testing Production"
CV="cv-${TYPE}-${PRODUCT}"
```

* Create cv-app-ansible content view

```
hammer content-view create --name "${CV}" --organization $ORG
```

* Add Repositories to cv-app-ansible

```
CV_PRODUCT="'Red Hat Ansible Engine'"
REPOS="$(mktemp)"
cat > $REPOS << EOF
'Red Hat Ansible Engine 2.6 RPMs for Red Hat Enterprise Linux 7 Server x86_64'
EOF

while read repo;
do
 echo hammer content-view add-repository --name "${CV}" --organization $ORG \
    --product "${CV_PRODUCT}" --repository "${repo}"|sh
done < $REPOS
```

 * Publish cv-app-ansible content view

```
hammer content-view publish --name "${CV}" --organization $ORG \
    --description "Initial publish"

CVID=$(hammer --csv content-view list --name "${CV}" --organization ${ORG} | grep -vi '^Content View ID,' | awk -F',' '{print $1}')
APP_CVID=`get_latest_version "${CV}"`
EAP_CV=$APP_CVID

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
