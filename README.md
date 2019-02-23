# Red Hat Products Content Views

**NOTICE:** *This is actively being cleaned up. Some things are missing*

This repo contains some bash scripting wrapper around the `hammer` command to create content vies for Red Hat products. Content views are created for base products such as Red Hat enterprise Linux Server and Glusterfs. Then composite content views are created to include products that depend on each other. For example, Glusterfs depends on RHEL, so the corresponding content view consists of both the RHEL and glusterfs content view. The corresponding activation keys are also created, one for each life cycle environment. In addition, the subscriptions are also attached to the activation keys.

Allot of this is based on the [10 Steps to Build an SOE: How Red Hat Satellite 6 Supports Setting up a Standard Operating Environment](https://access.redhat.com/articles/1585273).

## Usage

For now, make sure all the content views are created before you create products that are composite views. At some point I will update the script to do this in one shot.

* The `populate_satellite.sh` file is the main script.
* The `hammer_helper_functions` file contains all the functions that are source by `populate_satellite.sh`.
* The `products` contains the configuration file for each product content view or composite content view.

### Get Started

1. Clone this repo to your Satellite server
2. Setup hammer to connect to Satellite without being promoted for username and password
3. Edit the product config file, for example `products/rhv_content`
4. Run it `populate_satellite.sh products/rhv_content`

## Disclaimer 

All this work is the result my role a Solutions Architect to be able to quickly stand up a Satellite server. Please take the time to adopt it to your environment and needs, any feedback is always welcome. Probable the most important info here is the names of the repository_sets and repos that you need to enable in Satellite for each product.

## Products Covered

- Red Hat Enterprise Linux Server
- Red Hat Ansible Engine
- Red Hat Gluster Storage
- Red Hat Virtualization
- JBoss Enterprise Application Platform