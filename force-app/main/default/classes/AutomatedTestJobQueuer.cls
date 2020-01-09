/**
 * *
 */
public with sharing class AutomatedTestJobQueuer implements Schedulable {
    public void execute(SchedulableContext SC) {
        // get all unit test classes (excluding managed package unit tests)
        ApexClass[] testClasses = [FIND '@isTest' IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];

        if (testClasses.size() > 0) {
            ApexTestQueueItem[] queueItems = new List<ApexTestQueueItem>();
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
            } else {
                item = new ApexTestQueueItem(Id = '70923000000IVrhAAG');
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