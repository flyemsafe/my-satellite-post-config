#!/bin/bash

product_content=$1

# Gets user varaibles
source ./${product_content}
ORG_ID=$(hammer --csv organization list --search $ORG | grep -o [0-9])

# Gets Helper functions
source ./hammer_helper_functions

# Required Variables and Functions
enabled_products=$(mktemp)
all_products=$(mktemp)
ACTIVATION_KEYS=$(mktemp)
PRODUCT_SUBS_LIST=$(mktemp)

# Refresh user varaibles
source ./${product_content}

org="--organization ${ORG}"
# Create content view
if [ "$create_cv" == "yes" ];
then
    create_content_view $CV
fi

# Get the current repos associated with the content view
CV_REPOS_BEFORE=$(hammer --output json content-view info --name $CV --organization ACME | grep -A40 $CV | grep -B2 Label | grep ID | grep -o "[0-9]." | paste -sd "")
CV_REPOS=$(mktemp)
hammer content-view info --name $CV --organization ACME > $CV_REPOS

# Enable products not already enabled
if [ "$create_reposets" == "yes" ];
then
    # Get list of enabled products
    echo hammer --output json repository-set list --enabled=true $org|sh | awk -F':' '/Name/ {print $2}' > $enabled_products
    # Get list of all products
    echo hammer --output json repository-set list $org|sh | awk -F':' '/Name/ {print $2}' > $all_products
    while IFS=, read reposet repo release;
    do
        #product_exist=$(grep "$reposet" $all_products)
        #if [ "'${reposet}'" != "'${product_exist}'" ];
        grep "$reposet" $all_products >/dev/null
        if [ "$?" != "0" ];
        then
            echo "${reposet} does not exist"
        else
            grep "$reposet" $enabled_products >/dev/null
            if [ "$?" != "0" ];
            then
                echo "enabling $product reposet: $reposet"
                if [ "${release}A" == "A" ] || [ "${release}A" != '""' ];
                then
                    echo hammer repository-set enable --name "$reposet" --organization "$ORG" --basearch "$ARCH"
                else
                    echo hammer repository-set enable --name "$reposet" --organization "$ORG" --basearch "$ARCH" --release $release
                fi
            fi
        fi
    done<$REPOSITORY_SETS
fi


# Add repositories to content views
if [ "$add_cv_repos" == "yes" ];
then
    while IFS=, read reposet repo release;
    do
        RESULT=$(echo grep "$repo" $CV_REPOS|sh)
        if [ "${RESULT}A" == "A" ];
        then
            echo -n "adding $repo to $CV..."
            echo hammer content-view add-repository --name ${CV} $org --repository ${repo}|sh
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
    hammer content-view list $org > $CV_LIST
    
    if grep $CCV $CV_LIST >/dev/null;
    then
        echo "updating content view $CCV"
        echo hammer content-view update --name "$CCV" \
           $org --component-ids $CV_IDS|sh
    else
        echo "creating compositive cv $CCV"
        echo hammer content-view create --name "$CCV" \
            --composite --description "'CCV Role for $PRODUCT'" \
            $org --component-ids $CV_IDS|sh
    fi

    # populate content view
    promote_content_view $CCV

    # create activation keys
    TYPE=$CCV_TYPE
    create_activation_keys $CCV
fi


# Publish promote content view
if [ "$publish_promote" == "yes" ];
then
    # populate content view
    promote_content_view $CV
    # create activation keys
    TYPE=$CV_TYPE
    create_activation_keys $CV
fi

exit 0
