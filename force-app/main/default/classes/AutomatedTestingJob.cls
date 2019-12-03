public with sharing class AutomatedTestingJob implements Schedulable {
    public void execute(SchedulableContext SC) {
        processAsyncResults();
    }

    /**
     */
    @testVisible
    private static void processAsyncResults() {
        // parent job storage
        List<Scheduled_Test_Result__c> queuedTests = [SELECT Id, Name, Job_Id__c FROM Scheduled_Test_Result__c LIMIT 5];

        if (queuedTests != null && queuedTests.size() > 0) {
            Set<Id> parentJobIds = new Set<Id>();

            for (Scheduled_Test_Result__c queuedJob : queuedTests) {
                parentJobIds.add(queuedJob.Job_Id__c);
            }

            // list of classes with info on their test statuses (ie pass/fail)
            List<ApexTestQueueItem> classTestStatuses = getClassTestStatuses(parentJobIds);

            // map of parent job id to class test statuses
            Map<Id, List<ApexTestQueueItem>> groupedTestsByJob = new Map<Id, List<ApexTestQueueItem>>();
            for (ApexTestQueueItem classTestStatus : classTestStatuses) {
                // null check
                if (!groupedTestsByJob.containsKey(classTestStatus.ParentJobId)) {
                    groupedTestsByJob.put(classTestStatus.ParentJobId, new List<ApexTestQueueItem>());
                }

                groupedTestsByJob.get(classTestStatus.ParentJobId).add(classTestStatus);
            }

            Set<Id> completedAsyncIds = getCompletedAsyncJobsIds(groupedTestsByJob);

            if (completedAsyncIds != null && completedAsyncIds.size() > 0) {
                // each item is the actual result of a single test method
                List<ApexTestResult> testResults = checkMethodStatus(completedAsyncIds);

                // map job id to list of test results
                Map<Id, List<ApexTestResult>> groupedTestResultsByJob = new Map<Id, List<ApexTestResult>>();
                for (ApexTestResult testResult : testResults) {
                    // null check
                    if (!groupedTestResultsByJob.containsKey(testResult.AsyncApexJobId)) {
                        groupedTestResultsByJob.put(testResult.AsyncApexJobId, new List<ApexTestResult>());
                    }

                    groupedTestResultsByJob.get(testResult.AsyncApexJobId).add(testResult);
                }

                List<Scheduled_Test_Result__c> queuedTestsToDelete = new List<Scheduled_Test_Result__c>();

                for (List<ApexTestResult> jobTestResults : groupedTestResultsByJob.values()) {
                    processResults(jobTestResults);
                }

                for (Scheduled_Test_Result__c queuedTest : queuedTests) {
                    for (Id completedAsyncId : completedAsyncIds) {
                        if (queuedTest.Job_Id__c == completedAsyncId) {
                            queuedTestsToDelete.add(queuedTest);
                            break;
                        }
                    }

                    if (groupedTestsByJob.containsKey(queuedTest.Job_Id__c) == false) {
                        queuedTestsToDelete.add(queuedTest);
                    }
                }

                if (queuedTestsToDelete.size() > 0) {
                    // delete queuedTestsToDelete;
                }
            }
        }
    }

    /**
     * Checks to see if a parent job's list of queued up unit tests are done running.
     *
     * Only returns a set of parent job ids that have its units done (failed/aborrted/completed).
     *
     * @param groupedTestsByJob map of parent job ID to list of its queued unit tests
     */
    @testVisible
    private static Set<Id> getCompletedAsyncJobsIds(Map<Id, List<ApexTestQueueItem>> groupedTestsByJob) {
        Set<Id> completedAsyncJobIds = new Set<Id>();

        for (List<ApexTestQueueItem> jobTests : groupedTestsByJob.values()) {
            if (jobTests == null || jobTests.size() == 0) {
                continue;
            }

            Boolean allCompleted = true;

            for (ApexTestQueueItem queuedTest : jobTests) {
                if (
                    queuedTest.Status != 'Completed' &&
                    queuedTest.Status != 'Failed' &&
                    queuedTest.Status != 'Aborted'
                ) {
                    allCompleted = false;
                    break;
                }
            }

            if (allCompleted == true) {
                completedAsyncJobIds.add(jobTests[0].ParentJobId);
            }
        }

        return completedAsyncJobIds;
    }

    /**
     * Get the status and pass rate for each class whose tests were run by
     * the job (that correspond to the specified job ID).
     */
    @testVisible
    private static List<ApexTestQueueItem> getClassTestStatuses(Set<ID> jobIds) {
        return [
            SELECT ApexClass.Name, Status, ExtendedStatus, ParentJobId
            FROM ApexTestQueueItem
            WHERE ParentJobId IN :jobIds
        ];
    }

    /**
     * Queries and returns a list of apex test results. Each result item represents
     * a method's test result.
     *
     * @param jobIds parent job ID to filter on (equivalent to ApexTestQueueItem.ParentJobId)
     */
    @testVisible
    private static List<ApexTestResult> checkMethodStatus(Set<ID> jobIds) {
        return [
            SELECT
                Outcome,
                MethodName,
                Message,
                StackTrace,
                AsyncApexJobId,
                ApexClass.Name,
                ApexClass.Body,
                ApexClass.LengthWithoutComments,
                ApexClass.NamespacePrefix,
                ApexClass.Status,
                ApexLogId,
                ApexLog.DurationMilliseconds,
                ApexLog.Operation,
                ApexLog.Request,
                ApexLog.Status,
                ApexLog.Location,
                ApexLog.Application
            FROM ApexTestResult
            WHERE AsyncApexJobId IN :jobIds
        ];
    }

    /**
     */
    @testVisible
    private static void processResults(List<ApexTestResult> jobTestResults) {
        List<ApexTestResult> successTests = new List<ApexTestResult>();
        List<ApexTestResult> failedTests = new List<ApexTestResult>();

        for (ApexTestResult jobTestResult : jobTestResults) {
            if (jobTestResult.Outcome == 'Pass') {
                successTests.add(jobTestResult);
            } else {
                failedTests.add(jobTestResult);
            }
        }

        if (failedTests.size() > 0) {
            for (ApexTestResult testFailure : failedTests) {
                // testFailure.ApexClass.Name
                // testFailure.MethodName
                // testFailure.message
                // testFailure.stackTrace
                // testFailure.ApexLog.DurationMilliseconds
            }
        }
    }
}
