/**
 * Begins automated tests by executing all unit tests. Stores their parent
 * job in Scheduled_Test_Result__c custom object.
 *
 * AutomatedTestingJob.cls uses the parent job id to review the test results.
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
            insert queueItems;

            // grab the ParentJobId and store it for AutomatedTestingJob.cls
            ApexTestQueueItem item = [SELECT ParentJobId FROM ApexTestQueueItem WHERE Id = :queueItems[0].Id LIMIT 1];
            Scheduled_Test_Result__c atq = new Scheduled_Test_Result__c(Job_Id__c = item.ParentJobId);

            insert atq;
        }
    }
}
