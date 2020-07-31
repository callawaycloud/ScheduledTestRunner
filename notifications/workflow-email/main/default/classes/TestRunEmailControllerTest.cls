@isTest
private class TestRunEmailControllerTest {
    @isTest
    public static void controllerTest() {
        Test_Run__c testRun = new Test_Run__c(
            Name = 'Testing Test Run',
            Parent_Job_Ids__c = '7073t00005OHeNPCA1',
            Processed__c = false
        );
        insert testRun;
        Test_Run_Method_Result__c result = new Test_Run_Method_Result__c(
            Name = 'Test Class',
            Method_Name__c = 'Test Method',
            Message__c = 'Testing email controller',
            Method_Pass__c = false,
            First_Failure__c = Datetime.now(),
            Test_Run__c = testRun.Id
        );
        insert result;

        TestRunEmailController cont = new TestRunEmailController();
        cont.testRunId = testRun.Id;
        Map<String, List<Test_Run_Method_Result__c>> contMap = cont.getMethodResults();
        System.assert(!contMap.isEmpty());
        List<String> keys = cont.getMethodKeys();
        System.assertEquals(result.Name, keys[0]);
    }
}