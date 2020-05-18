/**
 * Unit tests for Run Processor
 */
@isTest
private class TestRunProcessorTest {
    @isTest
    public static void testQueuer() {
        TestRunProcessor testProcessor = new TestRunProcessor();
        testProcessor.testResults = generateApexTestResults();

        Test.StartTest();
        System.schedule('Automated Test Job Queuer [UNIT TESTING]', '0 0 23 * * ?', testProcessor);
        testProcessor.execute(null);
        List<Test_Run_Method_Result__c> processorResults = [
            SELECT Method_Name__c, Method_Pass__c
            FROM Test_Run_Method_Result__c
            WHERE Name = 'Generic'
        ];
        System.assertEquals('Test1', processorResults[0].Method_Name__c);
        System.assertEquals(true, processorResults[0].Method_Pass__c);

        Test.stopTest();
    }
    /**
     * Tests processPassFailDates() uses fake test "PassFailProccess" named
     * in Test Generator classes below.
     */
    @isTest
    public static void PassFailProcessorTest() {
        List<Test_Run_Method_Result__c> pastTestResults = generatePastTestRunResults();
        insert pastTestResults;

        //wait a second
        Integer start = System.Now().second();
        while (System.Now().second() < start + 1) {
        }

        TestRunProcessor testProcessor = new TestRunProcessor();
        testProcessor.testResults = generateApexTestResults();

        Test.StartTest();
        testProcessor.execute(null);
        List<Test_Run_Method_Result__c> processorResults = [
            SELECT
                Method_Name__c,
                Method_Pass__c,
                Test_Run__c,
                CreatedDate,
                First_Failure__c,
                Last_Success__c,
                Failure_Audit__c
            FROM Test_Run_Method_Result__c
            WHERE Name = 'PassFailProccess'
            ORDER BY CreatedDate DESC
        ];
        for (Test_Run_Method_Result__c tr : processorResults) {
            System.debug('Test: ' + tr.Method_Name__c);
            System.debug('Pass Fail: ' + tr.Method_Pass__c);
            System.debug('Date: ' + tr.CreatedDate);
            System.debug('Audit: ' + tr.Failure_Audit__c);
        }

        System.assertEquals('Test2', processorResults[0].Method_Name__c);
        System.assertNotEquals(processorResults[0].CreatedDate, processorResults[0].First_Failure__c);
        System.assertEquals('Method Passed', processorResults[2].Failure_Audit__c);

        Test.stopTest();
    }
    /**
     * Generates a List of ApexTestResult and returns them.
     * Also inserts a List of Test_Run__c records to mock seperate runs and for id purposes
     */
    private static List<ApexTestResult> generateApexTestResults() {
        List<Test_Run__c> testRun = new List<Test_Run__c>{
            new Test_Run__c(Parent_Job_Ids__c = '7073t00005OHeNPCA1', Processed__c = false)
        };
        insert testRun;
        List<ApexTestResult> testResults = new List<ApexTestResult>{
            new ApexTestResult(
                Outcome = 'Pass',
                MethodName = 'Test1',
                Message = 'asdf',
                StackTrace = 'asdf',
                AsyncApexJobId = testRun[0].Parent_Job_Ids__c,
                ApexClass = new ApexClass(Name = 'Generic')
            ),
            new ApexTestResult(
                Outcome = 'Fail',
                MethodName = 'Test2',
                Message = 'asdf',
                StackTrace = 'asdf',
                AsyncApexJobId = testRun[0].Parent_Job_Ids__c,
                ApexClass = new ApexClass(Name = 'PassFailProccess')
            )
        };
        return testResults;
    }
    /**
     * Generates a List of Test_Run_Method_Restult__c and inserts them.
     * Also inserts a List of Test_Run__c records to mock seperate runs and for id purposes
     */
    private static List<Test_Run_Method_Result__c> generatePastTestRunResults() {
        List<Test_Run__c> testRun = new List<Test_Run__c>{
            new Test_Run__c(Parent_Job_Ids__c = '7073t00005OHeNPAA1', Processed__c = true),
            new Test_Run__c(Parent_Job_Ids__c = '7073t00005OHbgxAAD', Processed__c = true)
        };
        insert testRun;
        List<Test_Run_Method_Result__c> testRunResults = new List<Test_Run_Method_Result__c>{
            new Test_Run_Method_Result__c(
                Message__c = 'asdf',
                Method_Name__c = 'Test2',
                Method_Pass__c = false,
                Name = 'PassFailProccess',
                Stack_Trace__c = 'asdf',
                Test_Run__c = testRun[0].Id
            ),
            new Test_Run_Method_Result__c(
                Message__c = 'asdf',
                Method_Name__c = 'Test2',
                Method_Pass__c = true,
                Name = 'PassFailProccess',
                Stack_Trace__c = 'asdf',
                Test_Run__c = testRun[1].Id
            )
        };
        return testRunResults;
    }
}