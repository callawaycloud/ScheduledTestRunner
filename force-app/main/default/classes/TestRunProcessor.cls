/**
 * This schedulable class does the following:
 *  - checks the status of the unit test runs
 *  - and if the test run is complete it will fire off actions to handle and
 *      parse the results.
 */
public with sharing class TestRunProcessor implements Schedulable {
    public void execute(SchedulableContext SC) {
        List<Test_Run__c> testRuns = [SELECT Id, Parent_Job_Ids__c FROM Test_Run__c WHERE Processed__c = false];

        for (Test_Run__c testRun : testRuns) {
            if (testRun.Parent_Job_Ids__c != null && allTestsComplete(testRun.Parent_Job_Ids__c)) {
                // each item of testResults is the actual result of a single test method
                List<ApexTestResult> testResults = getTestResults(testRun.Parent_Job_Ids__c);
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

    private List<ApexTestResult> getTestResults(String parentJobIds) {
        List<ApexTestResult> testResults = [
            SELECT Outcome, MethodName, Message, StackTrace, AsyncApexJobId, ApexClass.Name
            // ApexClass.Body, ApexClass.LengthWithoutComments, ApexClass.NamespacePrefix, ApexClass.Status, ApexLogId,
            // ApexLog.DurationMilliseconds, ApexLog.Operation, ApexLog.Request, ApexLog.Status, ApexLog.Location, ApexLog.Application
            FROM ApexTestResult
            WHERE AsyncApexJobId = :parentJobIds.split(',')
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

        List<Test_Run_Method_Result__c> result = processPassFailDates(results);
        insert result;
    }

    private List<Test_Run_Method_Result__c> processPassFailDates(List<Test_Run_Method_Result__c> result) {
        Map<String, List<Test_Run_Method_Result__c>> failedTests = new Map<String, List<Test_Run_Method_Result__c>>();
        for (Test_Run_Method_Result__c r : result) {
            if (!r.Method_Pass__c) {
                failedTests.put(r.Method_Name__c, new List<Test_Run_Method_Result__c>());
            }
        }
        List<Test_Run_Method_Result__c> failedCousins = [
            SELECT Id, Method_Name__c, Method_Pass__c, CreatedDate
            FROM Test_Run_Method_Result__c
            WHERE Method_Name__c IN :failedTests.keySet()
            ORDER BY CreatedDate DESC
        ];

        for (Test_Run_Method_Result__c f : failedCousins) {
            if (failedTests.containsKey(f.Method_Name__c)) {
                List<Test_Run_Method_Result__c> tempList = failedTests.get(f.Method_Name__c);
                tempList.add(f);
                failedTests.put(f.Method_Name__c, tempList);
            }
        }

        for (Test_Run_Method_Result__c r : result) {
            if (!r.Method_Pass__c) {
                r.First_Failure__c = r.CreatedDate;
                for (Test_Run_Method_Result__c f : failedTests.get(r.Method_Name__c)) {
                    if (r.Method_Name__c == f.Method_Name__c && !f.Method_Pass__c) {
                        r.First_Failure__c = f.CreatedDate;
                    }
                    if (r.Method_Name__c == f.Method_Name__c && f.Method_Pass__c) {
                        r.Last_Success__c = f.CreatedDate;
                        break;
                    }
                }
            }
        }
        return result;
    }
}