/**
 * This schedulable class does the following:
 *  - checks the status of the unit test runs
 *  - and if the test run is complete it will fire off actions to handle and
 *      parse the results.
 */
public with sharing class TestRunProcesssor implements Schedulable {
    public void execute(SchedulableContext SC) {
        List<Test_Run__c> testRuns = [
            SELECT Id, Parent_Job_Id__c, Total_Classes__c
            FROM Test_Run__c
            WHERE Processed__c = false
        ];

        for (Test_Run__c testRun : testRuns) {
            // System.assert(testRun.Parent_Job_Id__c != null);
            // // System.assert(false, 'maximus');
            // System.assert(false, 'maximus');
            if (testRun.Parent_Job_Id__c != null && allTestsComplete(testRun.Parent_Job_Id__c)) {
                // each item of testResults is the actual result of a single test method
                List<ApexTestResult> testResults = getTestResults(testRun.Parent_Job_Id__c);
                processTestResults(testRun, testResults);

                // update the test run
                testRun.Processed__c = true;
                update testRun;
            }
        }
    }

    private Boolean allTestsComplete(Id parentJobId) {
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
        List<ApexTestQueueItem> queueItems = [
            SELECT ApexClass.Name, Status, ExtendedStatus, ParentJobId
            FROM ApexTestQueueItem
            WHERE ParentJobId = :parentJobId
        ];

        if (Test.isRunningTest()) {
            queueItems.add(
                (ApexTestQueueItem) JSON.deserialize(
                    '{"ApexClass.Name":"TestRunProcesssorTest","Status":"Completed"}',
                    ApexTestQueueItem.class
                )
            );
        }

        return queueItems;
    }

    private List<ApexTestResult> getTestResults(Id parentJobId) {
        List<ApexTestResult> testResults = [
            SELECT Outcome, MethodName, Message, StackTrace, AsyncApexJobId, ApexClass.Name
            // ApexClass.Body, ApexClass.LengthWithoutComments, ApexClass.NamespacePrefix, ApexClass.Status, ApexLogId,
            // ApexLog.DurationMilliseconds, ApexLog.Operation, ApexLog.Request, ApexLog.Status, ApexLog.Location, ApexLog.Application
            FROM ApexTestResult
            WHERE AsyncApexJobId = :parentJobId
        ];

        if (Test.isRunningTest()) {
            testResults.add(
                (ApexTestResult) JSON.deserialize(
                    '{' +
                    '"Outcome":"asdf",' +
                    '"MethodName":"asdf",' +
                    '"Message":"asdf",' +
                    '"StackTrace":"asdf",' +
                    '"AsyncApexJobId":"asdf",' +
                    '"ApexClass.Name":"asdf"' +
                    '}',
                    ApexTestResult.class
                )
            );
        }

        return testResults;
    }

    /**
     * Process each unit test's method result and created a related Automated_Test_Job_Results__c
     * record.
     */
    private void processTestResults(Test_Run__c testRun, List<ApexTestResult> apexTestResults) {
        List<Test_Run_Method_Result__c> results = new List<Test_Run_Method_Result__c>();

        for (ApexTestResult apexTestResult : apexTestResults) {
            results.add(
                new Test_Run_Method_Result__c(
                    Message__c = apexTestResult.message,
                    Method_Name__c = apexTestResult.MethodName,
                    Method_Pass__c = apexTestResult.Outcome == 'Pass' ? true : false,
                    Name = apexTestResult.ApexClass.Name,
                    Stack_Trace__c = apexTestResult.stackTrace,
                    Test_Run__c = testRun.Id
                )
            );
        }

        insert results;
    }
}