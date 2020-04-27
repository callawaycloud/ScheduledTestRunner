/**
 * This scheduleable class fires starts all of the unit tests.
 *
 * Each execution of the org's unit tests will have a parent job id,
 * this is stored in Automated_Test_Package__c.
 *
 * AutomatedTestingJob.cls, also scheduleable, checks the status of the parent
 * job id. When it is complete it'll fire off and check the results.
 *
 * TLDR; this class starts the org's unit tests, but does nothing with the results.
 */
public with sharing class AutomatedTestJobQueuer implements Schedulable {
    public void execute(SchedulableContext SC) {
        // get all unit test classes (excluding managed package unit tests)
        ApexClass[] testClasses = [FIND '@isTest' IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];

        if (testClasses.size() > 0) {
            List<ApexTestQueueItem> queueItems = new List<ApexTestQueueItem>();
            for (ApexClass testClass : testClasses) {
                queueItems.add(new ApexTestQueueItem(ApexClassId = testClass.Id));
            }

            // bulk insert, when bulk inserted they will all contain the same ParentJobId
            if (!Test.isRunningTest()) {
                // can't queue unit tests while running a test
                insert queueItems;
            }

            // grab the ParentJobId and store it for AutomatedTestingJob.cls
            ApexTestQueueItem item;
            if (!Test.isRunningTest()) {
                item = [SELECT ParentJobId FROM ApexTestQueueItem WHERE Id = :queueItems[0].Id LIMIT 1];
            }

            Automated_Test_Package__c customSetting = [
                SELECT Id, Parent_Job_Id__c
                FROM Automated_Test_Package__c
                LIMIT 1
            ];

            customSetting.Parent_Job_Id__c = item.ParentJobId;
            update customSetting;
        }
    }
}