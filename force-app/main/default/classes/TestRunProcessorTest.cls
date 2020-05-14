/**
 * Unit tests for Run Processor
 */
@isTest
private class TestRunProcessorTest {
    @isTest
    public static void testQueuer() {
        List<ApexClass> classes = [SELECT Id, Name, Body FROM ApexClass WHERE Name = 'TestRunProcessorTest'];

        Test_Run__c testRun = new Test_Run__c(
            Parent_Job_Ids__c = classes[0].Id, // wrong id type but we just need a valid SFDC Id for now
            Processed__c = false
        );
        insert testRun;
        TestRunProcessor testProcessor = new TestRunProcessor();
        testProcessor.testResults = new List<ApexTestResult>{
            new ApexTestResult(
                Outcome = 'asdf',
                MethodName = 'asdf',
                Message = 'asdf',
                StackTrace = 'asdf',
                AsyncApexJobId = testRun.Parent_Job_Ids__c,
                ApexClass = new ApexClass(Name = 'asdf')
            )
        };
        Test.StartTest();
        System.schedule('Automated Test Job Queuer [UNIT TESTING]', '0 0 23 * * ?', testProcessor);
        Test.stopTest();
    }
}