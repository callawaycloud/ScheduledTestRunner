# Scheduled Test Runner

A Salesforce package for knowing the current status of your organization's unit tests.

Some notes:

-   scheduled to run at your own frequency
-   test runs pruned after 30 days of age

## Install

https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1C000000lIByQAM

## Setup

### Send Notifications

Optional notifications, currently via workflow emails only:

-   `sfdx force:source:convert -r notifications/workflow-email -d ./dist/workflow-email`
-   `sfdx force:mdapi:deploy -d .\dist\workflow-email\`
-   Update Workflow Action "Test Run Failure Notification Alert", to include your email addresses
-   Activate workflow "Send Test Run Failure Notification"

### Scheduling

Schedule the unit test run frequency (example below runs daily at 3am):

```
TestRunScheduler testRunner = new TestRunScheduler();
String sch = '0 0 3 * * ?'; // schedule interval time
System.Schedule('Test Runner', sch, testRunner);
```

Schedule the processor to check for finished test runs hourly, or more often if you want:

```
TestRunProcesssor testProcessor = new TestRunProcesssor();
String sch = '0 0 * * * ?'; // schedule interval time
System.Schedule('Test Processor', sch, testProcessor);
```

Tip: based on this setup you schedule TestRunScheduler an hour before you want it to be processed.

## Uninstall

Please check Salesforce's direction here: https://help.salesforce.com/articleView?id=distribution_uninstalling_packages.htm&type=5

Brief steps:

-   setup
-   search for "Installed Packages"
-   find Test Runner, click uninstall

## Developer Notes

### release new version

Make your updates, release a new version:

-   open `sfdx-project.json`
    -   increment `versionName` and `versionNumber` respectively
    -   save
-   `sfdx force:package:version:create -p TestRunner -d force-app -x --wait 10 -v CCC-SFDC-Production`

### Promote

Once you are ready to release the updated package, use the 04t\* Id from the new release to promote:

-   `sfdx force:package:version:promote -p 04t\*`
-   update `README.mdd` install step with the new install URL
