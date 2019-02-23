# Hammer Commands to Populate Satellite 6

This is a guide I use for populating my Satellite 6 with content.

**References**

- [dirkherrmann/soe-reference-architecture](https://github.com/dirkherrmann/soe-reference-architecture)
- [dmoessne/if-I-had-a-hammer](https://github.com/dmoessne/if-I-had-a-hammer)
- [shetze/hammer-scripts](https://github.com/shetze/hammer-scripts/blob/master/sat62-setup.sh)
- [theforeman/foreman_ansible_inventory](https://github.com/theforeman/foreman_ansible_inventory)


## Manifest


https://github.com/SatelliteQE/automation-tools/blob/10cf8566be5e70c1ced1b04ab4bebdb09310cea4/automation_tools/__init__.py#L2260


See (https://github.com/RedHatSatellite/rhsmTools/blob/master/rhsmDownloadManifest.py) for another example.

Another way is:
curl -s -u username:password -X PUT -k https://subscription.rhsm.stage.redhat.com/subscription/consumers/<UUID>/certificates?lazy_regen=false

curl -s -u username:password -k https://subscription.rhsm.stage.redhat.com/subscription/consumers/<UUID>/export/ > manifest.zip.

Roman, you may want to update your code in the automation-tools repo to issue a PUT to /consumers/<UUID>/certificates as I do above [1]. You'd want to do this because you would otherwise potentially download a manifest which has new metadata (such as new content sets/repos) but does not have the required Entitlement certificates to actually access the content.

- Rich


[1] - http://www.candlepinproject.org/swagger/?url=candlepin/swagger-2.0.13.json#!/consumers/regenerateEntitlementCertificates
```

## Access Insights

* [Configuring Basic Authentication for Red Hat Access Insights in Satellite 6](https://mojo.redhat.com/docs/DOC-1043937)

## Setup bashrc

### Functions

```
get_latest_version {
 CVID=$(hammer --csv content-view list --name $1 --organization ${ORG} | grep -vi '^Content View ID,' | awk -F',' '{print $1}' )
 VID=`hammer content-view version list --content-view-id ${CVID} | awk -F'|' '{print $1}' | sort -n | tac | head -n 1`
echo $VID
}

promote_content () {
  APP_CVID=`get_latest_version "$4"`
  hammer content-view version promote --content-view-id $2 \
    --organization $3 \
    --to-lifecycle-environment $1 \
   --id $APP_CVID \
   --async
}

add_cv_repo() {
  while read repo;
  do
    echo hammer content-view add-repository --name "${1}" --organization $2 --product "$3" --repository "${repo}"
  done < $4
}

create_activation_keys () {
  for LC_ENV in $(echo ${LC_ENVS})
  do
      LC_ENV_LOWER=$(echo ${LC_ENV} | tr '[[:upper:]' '[[:lower:]]')
      LC_ENV_UPPER=$(echo ${LC_ENV} | tr '[[:lower:]' '[[:upper:]]')
      ACT_KEY="act-${LC_ENV_LOWER}-${ROLE}-${ARCH}"

      grep "$ACT_KEY" $ACTIVATION_KEYS >/dev/null
      if [ "$?" -ne "0" ];
      then
        echo hammer activation-key create --name "$ACT_KEY" --content-view "$CV" --lifecycle-environment "${LC_ENV}" --organization "${ORG}"
      fi
      ACT_KEY_ID=$(hammer activation-key list --name $ACT_KEY --organization $ORG | grep -o "^[0-9].")

      for SubID in ${SubIDs}
      do
        subscription_list=$(mktemp)
        hammer --output csv activation-key subscriptions --organization $ORG --name "$ACT_KEY" > $subscription_list
        CURRENT_ID=$(grep $SubID $subscription_list | cut -d',' -f1)
        if [ "$CURRENT_ID" != "$SubID" ];
        then
          echo "echo currentID=$CURRENT_ID"
          echo "echo givenID=$SubID"
          echo hammer activation-key add-subscription --name "$ACT_KEY" --subscription-id "${SubID}" --organization "${ORG}"
        fi
      done

      while read repo;
      do
        echo hammer activation-key content-override --id $ACT_KEY_ID --organization "$ORG" \
--content-label "${repo}" --value 1
      done < $REPOS
  done
}

```
