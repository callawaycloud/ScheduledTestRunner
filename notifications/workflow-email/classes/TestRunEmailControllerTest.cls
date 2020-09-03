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

        List<Test_Run_Method_Result__c> methodResults = new List<Test_Run_Method_Result__c>{
            new Test_Run_Method_Result__c(
                Name = 'Test Class',
                Method_Name__c = 'Test Method',
                Message__c = 'Testing email controller',
                Method_Pass__c = false,
                First_Failure__c = Datetime.now(),
                Test_Run__c = testRun.Id
            ),
            new Test_Run_Method_Result__c(
                Name = 'Test Class2',
                Method_Name__c = 'Test Method2',
                Message__c = 'Testing email controller',
                Method_Pass__c = false,
                First_Failure__c = Datetime.now().addDays(-1),
                Test_Run__c = testRun.Id
            )
        };
        insert methodResults;

        TestRunEmailController cont = new TestRunEmailController();
        cont.testRunId = testRun.Id;
        Map<String, List<Test_Run_Method_Result__c>> firstFailMap = cont.getFirstFailureMap();
        Map<String, List<Test_Run_Method_Result__c>> remainMap = cont.getRemainingFailureMap();
        System.assert(firstFailMap.keySet().contains(methodResults[0].Name));
        System.assert(remainMap.keySet().contains(methodResults[1].Name));
    }
}