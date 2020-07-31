# Scheduled Test Runner

A Salesforce package to help monitor organization's unit tests health.

<img width="1264" alt="Test_Run__2020-05-05_03_00_07___Salesforce" src="https://user-images.githubusercontent.com/5217568/81127689-3c223900-8efc-11ea-94ab-7bfb34a4c957.png">

-   Setup to run via scheduled process
-   Test results are store in objects
    -   `Test_Run__c`: A test Job instance
    -   `Test_Run_Method_Result__c`: An individual test method result
    -    Results are pruned after 30 days
-   Tracks "First Failure" to help with debugging / noise reduction
-   Automaticly builds Audit Log query to help troubleshoot what changes might have caused a test to fail
-   Captures Run Time, which can help identify performance issues or slow tests

## Install

[Unlocked Package Install Link](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1C000000pQglQAE)

## Setup

### Scheduling

1. Schedule the unit test run frequency (example below runs daily at 3am):

```java
TestRunScheduler testRunner = new TestRunScheduler();
String sch = '0 0 3 * * ?'; // schedule interval time
System.Schedule('Test Runner', sch, testRunner);
```

2. Schedule the processor to check for finished test runs hourly (or more often if you want):

```java
TestRunProcessor testProcessor = new TestRunProcessor();
String sch = '0 15 * * * ?'; // schedule interval time
System.Schedule('Test Processor', sch, testProcessor);
```

**NOTES:**

-   If you find your test runs are failing inconsistently, you may need to [disabling "parallel" test runs](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_best_practices.htm)

### Sending Notifications

![Screen Shot 2020-07-31 at 1 41 14 PM](https://user-images.githubusercontent.com/5217568/89072011-08a54e00-d335-11ea-9ba9-10c5a03cb8ee.png)

To keep things as flexible & upgradable possible, we've decided not to package any notification logic with the "unlocked" package.

Since the results are stored in an object, you can you use tool of choice to receive notifications about failures.

However, we have included a simple workflow to send an email when a test fails.

**To install workflow email alert:**

-   run `sfdx force:source:convert -r notifications/workflow-email -d ./dist/workflow-email` to create a metadata package
-   run `sfdx force:mdapi:deploy -d ./dist/workflow-email/ -w -1` to deploy
-   Update Workflow Action "Test Run Failure Notification Alert", to include your email addresses

We may add more prebuilt notification methods in the future.

**TIP: If you only want to be notified of new failures, update the workflow to send if `Test_Run__r.New_Test_Failures__c > 0`**

## Development

### Releasing a new version

Make your updates, release a new version:

-   open `sfdx-project.json`
    -   increment `versionName` and `versionNumber` respectively
    -   save
-   `sfdx force:package:version:create -p TestRunner -d force-app -x --wait 10 -v CCC-SFDC-Production`

### Promote

Once you are ready to release the updated package, use the 04t\* Id from the new release to promote:

-   `sfdx force:package:version:promote -p 04t\*`
-   update `README.mdd` install step with the new install URL
