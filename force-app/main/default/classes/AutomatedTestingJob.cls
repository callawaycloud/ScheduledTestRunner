global with sharing class AutomatedTestingJob implements Schedulable {
    global void execute(SchedulableContext SC) {
        doExecute();
    }

    // Have to use a future method so the email will be sent out.
    @future(callout=true)
    public static void doExecute() {
        processAsyncResults();
    }

    public static void processAsyncResults() {
        List<Scheduled_Test_Result__c> queuedTests = [SELECT id, name, Job_Id__c FROM Scheduled_Test_Result__c LIMIT 5];

        if (queuedTests != null && queuedTests.size() > 0) {
            Set<Id> AsyncIds = new Set<Id>();

            for (Scheduled_Test_Result__c queuedJob : queuedTests) {
                AsyncIds.add(queuedJob.Job_Id__c);
            }

            List<ApexTestQueueItem> queuedItems = checkClassStatus(AsyncIds);

            Map<Id, List<ApexTestQueueItem>> groupedTestsByJob = new Map<Id, List<ApexTestQueueItem>>();

            for (ApexTestQueueItem atqi : queuedItems) {
                // null check
                if (!groupedTestsByJob.containsKey(atqi.ParentJobId)) {
                    groupedTestsByJob.put(atqi.ParentJobId, new List<ApexTestQueueItem>());
                }

                groupedTestsByJob.get(atqi.ParentJobId).add(atqi);
            }

            Set<Id> completedAsyncIds = getCompletedAsyncJobsIds(groupedTestsByJob);

            if (completedAsyncIds != null && completedAsyncIds.size() > 0) {
                List<ApexTestResult> testResults = checkMethodStatus(completedAsyncIds);

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
                    sendTestResultEmail(jobTestResults);
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
                    delete queuedTestsToDelete;
                }
            }
        }
    }

    public static Set<Id> getCompletedAsyncJobsIds(Map<Id, List<ApexTestQueueItem>> groupedTestsByJob) {
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

    private static void sendTestResultEmail(List<ApexTestResult> jobTestResults) {
        System.debug(' In sendTestResultEmail');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String emailAddress = 'max@callaway.cloud';

        String[] toAddresses = new List<String>{ emailAddress };

        mail.setToAddresses(toAddresses);

        String emailSubject = 'Dev Unit Test Results ' + String.valueOf(Date.today());

        mail.setSubject(emailSubject);

        String testResultEmailbody = getTestResultHtmlEmailBody(jobTestResults);

        mail.setHtmlBody(testResultEmailbody);
        Messaging.sendEmail(new List<Messaging.Email>{ mail });

        System.debug(' sent test results email');
    }

    private static String getTestResultHtmlEmailBody(List<ApexTestResult> jobTestResults) {
        System.debug(' In getTestResultHtmlEmailBody');

        List<ApexTestResult> successTests = new List<ApexTestResult>();
        List<ApexTestResult> failedTests = new List<ApexTestResult>();

        for (ApexTestResult jobTestResult : jobTestResults) {
            if (jobTestResult.Outcome == 'Pass') {
                successTests.add(jobTestResult);
            } else {
                failedTests.add(jobTestResult);
            }
        }

        Integer numTestsRun = successTests.size() + failedTests.size();
        Integer numFailures = failedTests.size();
        Integer successNum = numTestsRun - numFailures;

        if (successNum < 0) {
            successNum = 0;
        }

        String testResultBody = '';

        // Unfortunately, css has to be inlined because many email service providers now exclude external CSS
        // because it can pose a security risk.
        testResultBody += '<td style="text-align: right;">' + numTestsRun + '';
        testResultBody += '<td style="text-align: right;">' + numFailures + '';
        testResultBody += '<td style="text-align: right;">' + successNum + '';

        testResultBody += '<table><tbody><tr class="firstTr"><td>Tests Run:</td></tr><tr><td>Failure Count:</td></tr><tr><td>Success Count:</td></tr></tbody></table>';

        if (numFailures > 0) {
            testResultBody += '<div style="margin: 5px 0px; font-weight: bold;">Test Failures</div>';

            testResultBody += '';

            testResultBody += '';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Test Class</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Unit Test</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Message</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Stack Trace</th>';
            testResultBody += '<th style="text-align: left; padding-left: 5px;">Time (Ms)</th>';
            testResultBody += '';

            for (ApexTestResult testFailure : failedTests) {
                testResultBody += '';

                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.ApexClass.Name + '';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.MethodName + '';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.message + '';
                testResultBody += '<td style="padding: 5px; vertical-align: top;">' + testFailure.stackTrace + '';
                testResultBody +=
                    '<td style="padding: 5px; vertical-align: top;">' +
                    testFailure.ApexLog.DurationMilliseconds +
                    '';
                //testResultBody += '<td style="vertical-align: top;">' + testFailure.type_x +'';

                testResultBody += '';
            }

            testResultBody += '<table><tbody><tr></tr><tr></tr></tbody></table>';
        }

        return testResultBody;
    }

    // Get the status and pass rate for each class

    // whose tests were run by the job.

    // that correspond to the specified job ID.

    public static List<ApexTestQueueItem> checkClassStatus(Set<ID> jobIds) {
        ApexTestQueueItem[] items = [
            SELECT ApexClass.Name, Status, ExtendedStatus, ParentJobId
            FROM ApexTestQueueItem
            WHERE ParentJobId IN :jobIds
        ];

        for (ApexTestQueueItem item : items) {
            String extStatus = item.extendedstatus == null ? '' : item.extendedStatus;
            System.debug(item.ApexClass.Name + ': ' + item.Status + extStatus);
        }

        return items;
    }

    // Get the result for each test method that was executed.

    public static List<ApexTestResult> checkMethodStatus(Set<ID> jobIds) {
        ApexTestResult[] results = [
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

        for (ApexTestResult atr : results) {
            System.debug(atr.ApexClass.Name + '.' + atr.MethodName + ': ' + atr.Outcome);
            if (atr.message != null) {
                System.debug(atr.Message + '\n at ' + atr.StackTrace);
            }
        }

        return results;
    }
}
