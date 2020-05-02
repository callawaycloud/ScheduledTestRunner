/**
 * This class starts the unit test run.
 *
 * Each execution of the org's unit tests will have a parent job id,
 * this is stored in Test_Run__c.
 *
 * TestRunProcesssor.cls, also scheduleable, checks the status of the test
 * run. When it is complete it'll fire off and check the results.
 *
 * TLDR; this class starts the org's unit tests, but does nothing with the results.
 */
public with sharing class TestRunScheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        // get all unit test classes (excluding managed package unit tests)
        List<ApexClass> testClasses = [FIND '@isTest' IN ALL FIELDS RETURNING ApexClass(Id, Name)][0];

        if (testClasses.size() > 0) {
            List<List<ApexTestQueueItem>> queueItems = new List<List<ApexTestQueueItem>>();
            List<ApexTestQueueItem> innerQueueItems = new List<ApexTestQueueItem>();
            Integer counter = 0;

            for (ApexClass testClass : testClasses) {
                counter++;
                innerQueueItems.add(new ApexTestQueueItem(ApexClassId = testClass.Id));

                if (innerQueueItems.size() == 200) {
                    queueItems.add(innerQueueItems);
                    innerQueueItems = new List<ApexTestQueueItem>();
                }
            }

            if (innerQueueItems.size() > 0) {
                queueItems.add(innerQueueItems);
            }

            List<Id> parentIds = new List<Id>();
            Set<Id> testQueueIds = new Set<Id>();

            // bulk insert, when bulk inserted they will all contain the same ParentJobId
            if (!Test.isRunningTest()) {
                // can't queue unit tests while running a test
                for (List<ApexTestQueueItem> queueItemsSubset : queueItems) {
                    insert queueItemsSubset;
                    testQueueIds.add(queueItemsSubset[0].Id);
                }

                for (ApexTestQueueItem queueItem : [
                    SELECT ParentJobId
                    FROM ApexTestQueueItem
                    WHERE Id IN :testQueueIds
                ]) {
                    parentIds.add(queueItem.ParentJobId);
                }
            }

            Test_Run__c newRun = new Test_Run__c(
                Name = 'Test Run: ' + String.valueOf(DateTime.now()),
                Parent_Job_Ids__c = Test.isRunningTest() ? 'testingParentJobId' : String.join(parentIds, ','),
                Processed__c = false
            );

            insert newRun;
        }

        clearOldRuns();
    }

    public void clearOldRuns() {
        // delete completed runs older than a month, will remove child Test_Run_Method_Result__c tuples as well
        delete [SELECT Id FROM Test_Run__c WHERE Processed__c = true AND CreatedDate > LAST_N_DAYS:30];
    }
}