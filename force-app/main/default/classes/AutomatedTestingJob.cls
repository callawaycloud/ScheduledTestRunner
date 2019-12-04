/**
 *
 */
public with sharing class AutomatedTestingJob implements Schedulable {
    private Automated_Test_Package__c settings;

    public void execute(SchedulableContext SC) {
        settings = [SELECT Id, Parent_Job_Id__c FROM Automated_Test_Package__c][0];
        processAsyncResults();
    }

    /**
     *
     */
    @testVisible
    private void processAsyncResults() {
        if (settings.Parent_Job_Id__c != null) {
            // list of classes with info on their test statuses (ie pass/fail)
            List<ApexTestQueueItem> classTestStatuses = getClassTestStatuses(settings.Parent_Job_Id__c);

            Boolean testsDoneRunning = allTestsComplete(classTestStatuses);

            if (testsDoneRunning) {
                // each item is the actual result of a single test method
                List<ApexTestResult> testResults = getTestResults(settings.Parent_Job_Id__c);
                processTestResults(testResults);
            }
        }
    }

    /**
     *
     */
    @testVisible
    private boolean allTestsComplete(List<ApexTestQueueItem> classTestStatuses) {
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

    /**
     *
     */
    @testVisible
    private static List<ApexTestQueueItem> getClassTestStatuses(Id parentJobId) {
        return [
            SELECT ApexClass.Name, Status, ExtendedStatus, ParentJobId
            FROM ApexTestQueueItem
            WHERE ParentJobId = :parentJobId
        ];
    }

    /**
     *
     */
    @testVisible
    private static List<ApexTestResult> getTestResults(Id jobId) {
        return [
            SELECT Outcome, MethodName, Message, StackTrace, AsyncApexJobId, ApexClass.Name
            // ApexClass.Body, ApexClass.LengthWithoutComments, ApexClass.NamespacePrefix, ApexClass.Status, ApexLogId,
            // ApexLog.DurationMilliseconds, ApexLog.Operation, ApexLog.Request, ApexLog.Status, ApexLog.Location, ApexLog.Application
            FROM ApexTestResult
            WHERE AsyncApexJobId = :jobId
        ];
    }

    /**
     */
    @testVisible
    private static void processTestResults(List<ApexTestResult> jobTestResults) {
        // first clear all old results
        delete [SELECT Id FROM Automated_Test_Job_Results__c];

        List<Automated_Test_Job_Results__c> results = new List<Automated_Test_Job_Results__c>();

        for (ApexTestResult jobTestResult : jobTestResults) {
            results.add(
                new Automated_Test_Job_Results__c(
                    Name = jobTestResult.ApexClass.Name,
                    Method_Name__c = jobTestResult.MethodName,
                    Message__c = jobTestResult.message,
                    Stack_Trace__c = jobTestResult.stackTrace,
                    Method_Pass__c = jobTestResult.Outcome == 'Pass' ? true : false
                )
            );
        }

        insert results;
    }
}
