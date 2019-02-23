#!/bin/bash

product_content=$1

# Gets user varaibles
source ./${product_content}
ORG_ID=$(hammer --csv organization list --search $ORG | grep -o [0-9])

# Gets Helper functions
source ./hammer_helper_functions

# Required Variables and Functions
enabled_products=$(mktemp)
ACTIVATION_KEYS=$(mktemp)
PRODUCT_SUBS_LIST=$(mktemp)

# Refresh user varaibles
source ./${product_content}

#echo ""
# Create content view
create_content_view $CV

# Get the current repos associated with the content view
CV_REPOS_BEFORE=$(hammer --output json content-view info --name $CV --organization ACME | grep -A40 $CV | grep -B2 Label | grep ID | grep -o "[0-9]." | paste -sd "")
CV_REPOS=$(mktemp)
hammer content-view info --name $CV --organization ACME > $CV_REPOS

# Enable products not already enabled
if [ "$create_reposets" == "yes" ];
then
while IFS=, read product reposet repo release;
do
  # Get list of enabled products
  echo hammer --output json repository-set list --enabled=true --product "$product" --organization $ORG|sh | awk '/Name/ {print $0}' > $enabled_products
  grep "$reposet" $enabled_products >/dev/null
  if [ "$?" -ne "0" ];
  then
      echo "enabling $product reposet: $reposet"
      echo hammer repository-set enable --name "$reposet" --product "$product" --organization "$ORG" --basearch "$ARCH" "$release"|sh
  fi

  #echo ""
  # Add repos to content view
  RESULT=$(echo grep "$repo" $CV_REPOS|sh)
  if [ "${RESULT}A" == "A" ];
  then
      echo -n "adding $repo to $CV..."
      echo hammer content-view add-repository --name ${CV} --organization $ORG --product ${product} --repository ${repo}|sh
  fi
done<$REPOSITORY_SETS
fi

# composite content views
if [ "$create_ccv" == "yes" ];
then
    # populate content view
    #promote_content_view $CV
    # Get the current repos associated with the content view
    CV_REPOS_BEFORE=$(hammer --output json content-view info --name $CV --organization ACME | \
                    grep -A40 $CV | grep -B2 Label | grep ID | grep -o "[0-9]." | paste -sd "")
    result=$(for cv in $(echo $composite_cv); do get_latest_version $cv; done)
    CV_IDS=$(echo $result | sed -e "s/ /,/g")

    CV_LIST=$(mktemp)
    hammer content-view list --organization $ORG > $CV_LIST
    
    if grep $CCV $CV_LIST >/dev/null;
    then
        echo "updating content view $CCV"
        echo hammer content-view update --name "$CCV" \
           --organization $ORG --component-ids $CV_IDS|sh
    else
        echo "creating compositive cv $CCV"
        echo hammer content-view create --name "$CCV" \
            --composite --description "'CCV Role for $PRODUCT'" \
            --organization $ORG --component-ids $CV_IDS|sh
    fi

    # populate content view
    promote_content_view $CCV

    # create activation keys
    TYPE=$CCV_TYPE
    create_activation_keys $CCV
else
    # populate content view
    promote_content_view $CV
    # create activation keys
    TYPE=$CV_TYPE
    create_activation_keys $CV
fi

exit 0
