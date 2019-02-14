
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
