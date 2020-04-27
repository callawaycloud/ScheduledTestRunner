/**
 * This schedulable class
 *  - checks the status of the unit test runs
 *  - and if the test run is complete it will fire off actions to handle and
 *      parse the results.
 */
public with sharing class AutomatedTestingJob implements Schedulable {
    public void execute(SchedulableContext SC) {
        List<Automated_Test_Package__c> automatedTestRuns = [
            SELECT Id, Parent_Job_Id__c
            FROM Automated_Test_Package__c
        ];

        for (Automated_Test_Package__c automatedTestRun : automatedTestRuns) {
            processAsyncResults(automatedTestRun.Parent_Job_Id__c);
        }
    }

    private void processAsyncResults(Id parentJobId) {
        System.debug('Processing Async Results for parent job: ' + parentJobId);

        if (parentJobId != null) {
            if (allTestsComplete(parentJobId)) {
                // each item is the actual result of a single test method
                List<ApexTestResult> testResults = getTestResults(parentJobId);
                processTestResults(testResults, parentJobId);
            }
        }
    }

    private boolean allTestsComplete(Id parentJobId) {
        List<ApexTestQueueItem> classTestStatuses = getClassTestStatuses(parentJobId);

        if (classTestStatuses == null || classTestStatuses.size() == 0) {
            return false;
        }

        for (ApexTestQueueItem classTestStatus : classTestStatuses) {
            if (
                classTestStatus.Status != 'Completed' &&
                classTestStatus.Status != 'Failed' &&
                classTestStatus.Status != 'Aborted'
            ) {
                return false;
            }
        }

        return true;
    }

    private List<ApexTestQueueItem> getClassTestStatuses(Id parentJobId) {
        return [
            SELECT ApexClass.Name, Status, ExtendedStatus, ParentJobId
            FROM ApexTestQueueItem
            WHERE ParentJobId = :parentJobId
        ];
    }

    private List<ApexTestResult> getTestResults(Id parentJobId) {
        return [
            SELECT Outcome, MethodName, Message, StackTrace, AsyncApexJobId, ApexClass.Name
            // ApexClass.Body, ApexClass.LengthWithoutComments, ApexClass.NamespacePrefix, ApexClass.Status, ApexLogId,
            // ApexLog.DurationMilliseconds, ApexLog.Operation, ApexLog.Request, ApexLog.Status, ApexLog.Location, ApexLog.Application
            FROM ApexTestResult
            WHERE AsyncApexJobId = :parentJobId
        ];
    }

    /**
     * Process each unit test's method result and created a related Automated_Test_Job_Results__c
     * record.
     */
    private void processTestResults(List<ApexTestResult> jobTestResults, Id parentJobId) {
        // first clear all old results
        delete [SELECT Id FROM Automated_Test_Job_Results__c];

        List<Automated_Test_Job_Results__c> results = new List<Automated_Test_Job_Results__c>();

        for (ApexTestResult jobTestResult : jobTestResults) {
            results.add(
                new Automated_Test_Job_Results__c(
                    Message__c = jobTestResult.message,
                    Method_Name__c = jobTestResult.MethodName,
                    Method_Pass__c = jobTestResult.Outcome == 'Pass' ? true : false,
                    Name = jobTestResult.ApexClass.Name,
                    Parent_Job_Id__c = parentJobId,
                    Stack_Trace__c = jobTestResult.stackTrace
                )
            );
        }

        insert results;
    }
}