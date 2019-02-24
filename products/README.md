# Product Configuration Files

These are the configuration files use to setup a Red Hat product content or composite content view.

## Explanation


* Must be changed

```
ORG=ACME
ARCH="x86_64"
LC_ENVS="Testing Production"
```

* Change to match the current product release or to your desire
  
```
CV_PRODUCT="rhv4u2"
CV_DESCRIPTION='"Red Hat Virtualization 4.2"'
```

* Change to your desire, refer to the 10 steps refarch

```
CV_TYPE="virt"
CCV_TYPE="infra"
```

* Change if not RHEL7
  
```
releasever="7Server"
```

* This constructs the CV and CCV names
  
```
if [ "$CV_TYPE" != "os" ];
then
    ROLE=$(echo ${CV_PRODUCT} | tr '[:upper:]' '[:lower:]')
else
    ROLE=$(echo ${CV_PRODUCT}-${releasever}-${ARCH} | tr '[:upper:]' '[:lower:]')
fi

CV="cv-${CV_TYPE}-${ROLE}"
CCV="ccv-${CCV_TYPE}-${CV_PRODUCT}"
```

* Should we publish and promote CV
	- yes/no - publish if changes to CV or not
	-  force - always publish

```
publish_promote=yes
```

* Should repository sets be created. This required if creating the CV/CCV for the first time.
	- yes/no

```
create_reposets=yes
```

* Add the repositories required for the Red Hat Product

```
REPOSITORY_SETS=$(mktemp)
cat > $REPOSITORY_SETS <<EOF
"Red Hat Virtualization Manager", "Red Hat Virtualization Manager v4.2 (RHEL 7 Server) (RPMs)", "Red Hat Virtualization Manager 4 Tools RHEL 7 Server RPMs x86_64",
"Red Hat Virtualization Manager", "Red Hat Virtualization Manager 4 Tools (RHEL 7 Server) (RPMs)", "Red Hat Virtualization Manager v4.2 RHEL 7 Server RPMs x86_64", --releasever $releaseve
"Red Hat Virtualization", "Red Hat Virtualization 4 Management Agents for RHEL 7 (RPMs)", "Red Hat Virtualization 4 Management Agents for RHEL 7 RPMs x86_64 7Server", --releasever $releasever
"Red Hat Virtualization Host", "Red Hat Virtualization Host 7 (RPMs)", "Red Hat Virtualization Host 7 RPMs x86_64", --releasever $releasever
"JBoss Enterprise Application Platform", "JBoss Enterprise Application Platform 7.2 (RHEL 7 Server) (RPMs)", "JBoss Enterprise Application Platform 7.2 RHEL 7 Server RPMs x86_64",
EOF
```

* Should activation-keys be created, requires ACTKEY_REPOS
	- yes/no

```
create_activationkey=no
```

* Add the repos you want the activation key to enable

```
ACTKEY_REPOS="$(mktemp)"
cat > $ACTKEY_REPOS << EOF
rhel-7-server-rpms
rhel-7-server-supplementary-rpms
rhel-7-server-rhv-4.2-manager-rpms
rhel-7-server-rhv-4-manager-tools-rpms
rhel-7-server-ansible-2-rpms
jb-eap-7-for-rhel-7-server-rpms
EOF
```

* Should this be a composite content view?
	- yes/no - if yes

```
create_ccv=no
```
* Make sure to change `composite_cv` variable with the correct CVs

```
composite_cv='cv-os-rhel-7server cv-app-rhv'
```



