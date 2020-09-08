/**
 * This schedulable class does the following:
 *  - checks the status of the unit test runs
 *  - and if the test run is complete it will fire off actions to handle and
 *      parse the results.
 */
public with sharing class TestRunProcessor implements Schedulable {
    @testVisible
    private List<ApexTestResult> testResults;

    public void execute(SchedulableContext SC) {
        List<Test_Run__c> testRuns = [SELECT Id, Parent_Job_Ids__c FROM Test_Run__c WHERE Processed__c = false];

        for (Test_Run__c testRun : testRuns) {
            if (testRun.Parent_Job_Ids__c != null && allTestsComplete(testRun.Parent_Job_Ids__c)) {
                // each item of testResults is the actual result of a single test method
                getTestResults(testRun.Parent_Job_Ids__c);
                processTestResults(testRun, testResults);
                // update the test run
                testRun.Processed__c = true;
                update testRun;
            }
        }
    }

    private Boolean allTestsComplete(String parentJobIds) {
        List<ApexTestQueueItem> classTestStatuses = getClassTestStatuses(parentJobIds);

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

    private List<ApexTestQueueItem> getClassTestStatuses(String parentJobIds) {
        List<ApexTestQueueItem> queueItems = [
            SELECT ApexClass.Name, Status, ExtendedStatus, ParentJobId
            FROM ApexTestQueueItem
            WHERE ParentJobId IN :parentJobIds.split(',')
        ];

        if (Test.isRunningTest()) {
            queueItems.add(
                (ApexTestQueueItem) JSON.deserialize(
                    '{"ApexClass.Name":"TestRunProcessorTest","Status":"Completed"}',
                    ApexTestQueueItem.class
                )
            );
        }

        return queueItems;
    }

    private void getTestResults(String parentJobIds) {
        if (!Test.isRunningTest()) {
            testResults = [
                SELECT Outcome, MethodName, Message, StackTrace, AsyncApexJobId, ApexClass.Name, RunTime
                // ApexClass.Body, ApexClass.LengthWithoutComments, ApexClass.NamespacePrefix, ApexClass.Status, ApexLogId,
                // ApexLog.DurationMilliseconds, ApexLog.Operation, ApexLog.Request, ApexLog.Status, ApexLog.Location, ApexLog.Application
                FROM ApexTestResult
                WHERE AsyncApexJobId = :parentJobIds.split(',')
            ];
        }
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
                    Run_Time__c = apexTestResult.RunTime,
                    Test_Run__c = testRun.Id
                )
            );
        }
        List<Test_Run_Method_Result__c> failedTests = new List<Test_Run_Method_Result__c>();
        for (Test_Run_Method_Result__c r : results) {
            if (!r.Method_Pass__c) {
                failedTests.add(r);
            }
        }
        processPassFailDates(testRun, failedTests);
        update testRun;
        insert results;
    }

    private void processPassFailDates(Test_Run__c testRun, List<Test_Run_Method_Result__c> failedTests) {
        Map<String, List<Test_Run_Method_Result__c>> previousResultsMap = new Map<String, List<Test_Run_Method_Result__c>>();
        for (Test_Run_Method_Result__c r : failedTests) {
            previousResultsMap.put(r.Method_Name__c, new List<Test_Run_Method_Result__c>());
        }
        List<Test_Run_Method_Result__c> previousResults = [
            SELECT Id, Method_Name__c, Method_Pass__c, CreatedDate
            FROM Test_Run_Method_Result__c
            WHERE Method_Name__c IN :previousResultsMap.keySet()
            ORDER BY CreatedDate DESC
        ];

        for (Test_Run_Method_Result__c f : previousResults) {
            if (previousResultsMap.containsKey(f.Method_Name__c)) {
                List<Test_Run_Method_Result__c> tempList = previousResultsMap.get(f.Method_Name__c);
                tempList.add(f);
            }
        }

        Integer newTestFailures = 0;
        for (Test_Run_Method_Result__c failure : failedTests) {
            failure.First_Failure__c = Datetime.now();
            Boolean newFailure = true;
            for (Test_Run_Method_Result__c previousResult : previousResultsMap.get(failure.Method_Name__c)) {
                if (failure.Method_Name__c == previousResult.Method_Name__c && !previousResult.Method_Pass__c) {
                    newFailure = false;
                    failure.First_Failure__c = previousResult.CreatedDate;
                }
                if (failure.Method_Name__c == previousResult.Method_Name__c && previousResult.Method_Pass__c) {
                    failure.Last_Success__c = previousResult.CreatedDate;
                    break;
                }
            }
            if (newFailure) {
                failure.New_Failure__c = true;
                newTestFailures++;
            }
        }
        testRun.New_Failures__c = newTestFailures;
    }
}