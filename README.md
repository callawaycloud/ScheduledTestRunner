# Scheduled Test Runner

A Salesforce package for knowing the current status of your organization's unit tests.

maximus / todo test runs kept for 30 days, then deleted

## Install

https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1C000000lI7HQAU

## Setup

### send notifications

Update Workflow Action: Test Run Failure Notification Alert, to include your email addresses
Activate : Send Test Run Failure Notification

### Scheduling

Schedule scheduler

```

```

Schedule

```

```

## Uninstall

TODO

## Developer Notes

### release new version

-   sfdx force:package:version:create -p TestRunner -d force-app -x --wait 10 -v CCC-SFDC-Production

### promote

-   sfdx force:package:version:promote -p 04t\*
