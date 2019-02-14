get_latest_version () {
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

activation_keys () {
  hammer --output json activation-key list --organization "$ORG"| awk '/Name/ {print $0}' > $1
}

create_activation_keys () {

  ACTIVATION_KEYS=$(mktemp)
  activation_keys $ACTIVATION_KEYS
  for LC_ENV in $(echo ${LC_ENVS})
  do
      LC_ENV_LOWER=$(echo ${LC_ENV} | tr '[[:upper:]' '[[:lower:]]')
      LC_ENV_UPPER=$(echo ${LC_ENV} | tr '[[:lower:]' '[[:upper:]]')
      ACT_KEY="act-${LC_ENV_LOWER}-${ROLE}-${ARCH}"

      grep "$ACT_KEY" $ACTIVATION_KEYS >/dev/null
      if [ "$?" -ne "0" ];
      then
        echo hammer activation-key create --name "$ACT_KEY" --content-view "$CCV" --lifecycle-environment "${LC_ENV}" --organization "${ORG}"|sh
      fi

      ACT_KEY_ID=$(hammer activation-key list --name $ACT_KEY --organization $ORG | grep -o "^[0-9].")

      if [ -n "$ACT_KEY_ID" ]; then
          for SubID in ${SubIDs}
          do
              subscription_list=$(mktemp)
              hammer --output csv activation-key subscriptions --organization $ORG --name "$ACT_KEY" > $subscription_list
              CURRENT_IDS=$(mktemp)
              awk -F, '!/ID/ { print $1 }' $subscription_list >$CURRENT_IDS


              result=$(grep -q $SubID $CURRENT_IDS; echo $?)
              if [ $result -eq 1 ]; then 
                echo hammer activation-key add-subscription --name "$ACT_KEY" --subscription-id "${SubID}" --organization "${ORG}"|sh
              fi

              # Remove subscription from activation key
              for id in $(cat $CURRENT_IDS);
              do
                  result=$(echo $SubIDs | grep -q $id; echo $?)
                  if [ $result -eq 1 ]; then
                    echo hammer activation-key remove-subscription --name "$ACT_KEY" --subscription-id "${id}" --organization "${ORG}"|sh
                  fi
              done
          done

          while read repo;
          do
            echo hammer activation-key content-override --id $ACT_KEY_ID --organization "$ORG" --content-label "${repo}" --value 1|sh
          done < $REPOS

          # Disable auto-attach because it breaks multiple subscriptions
          # https://access.redhat.com/solutions/3346911
          echo hammer activation-key update --auto-attach no --id "$ACT_KEY_ID"|sh
      fi
  done
}

find_subscription () {
    if [ -z "$2" ]; then
    #if [[ -z "${2+present}" ]]; then
      hammer --output json subscription list --per-page 9999 --organization ${ORG} | grep -B2 -A7 "$1"
    else
       hammer --output json subscription list --per-page 9999 --organization ${ORG} | grep -B2 -A7 "$1" | grep -A1 -B8 "\"Quantity\": $2," | awk -F, '/"ID":/ {print $1}' | awk '{print $2}'
    fi
}

create_content_view () {
    ENABLED_CONTENT_VIEWS=$(mktemp)
    hammer --output json content-view list --organization "$ORG"| awk '/Name/ {print $0}' > $ENABLED_CONTENT_VIEWS
    grep "$CV" $ENABLED_CONTENT_VIEWS >/dev/null
    if [ "$?" -ne "0" ];
    then
        hammer content-view create --name "$CV" --description "$CV_DESCRIPTION" --organization "$ORG"
    fi
}

sync_container_repos () {

    REPOS_LIST=$1
    CONTAINER_REPOS="$(mktemp)"
    echo hammer --output csv repository list --organization $ORG --product="'$PRODUCT'"|sh | awk -F',' '/docker/ {print $2}' > $CONTAINER_REPOS
    
    while read repo;
    do
        getlabel=$(echo $repo|sed 's#/#-#')
        label="container-${getlabel}"
        name="Container $getlabel"
        upstream_name="$repo"

        RESULT=$(echo grep -q "'$name'" $CONTAINER_REPOS|sh; echo $?)
        if [ $RESULT -eq 1 ];
        then
            echo hammer repository create  --organization "$ORG" --name="'$name'" --label="$label" --product="'$PRODUCT'" --content-type="$PRODUCT_REPO_TYPE" --publish-via-http=true --url="$PRODUCT_REPO_URL" --docker-upstream-name="'$upstream_name'"|sh
        fi
    done<$REPOS_LIST

    while read repo;
    do
        getlabel=$(echo $repo|sed 's#/#-#')
        label="container-${getlabel}"
        name="Container $getlabel"

        echo "Checking if $name needs syncing"
        RESULT=$(echo hammer repository info --organization "$ORG" --product "'$PRODUCT'" --name "'$name'"|sh | awk '/Status:/ {print $2}')
        if [ "$RESULT" != "Success" ];
        then
            echo hammer repository synchronize --organization "$ORG" --product "'$PRODUCT'" --name "'$name'"|sh
        fi
    done<$REPOS_LIST
}
