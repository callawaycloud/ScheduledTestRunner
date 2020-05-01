/**
 *
 */
@isTest
private class TestRunSchedulerTest {
    @isTest
    public static void testRunTest() {
        List<ApexClass> classes = [SELECT Id, Name, Body FROM ApexClass WHERE Name = 'TestRunSchedulerTest'];

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_SOSL.htm
        Test.setFixedSearchResults(new List<Id>{ classes[0].Id }); // ApexClass result type Id for search queries

        Test.StartTest();
        System.schedule('Automated Test Job [UNIT TESTING]', '0 0 23 * * ?', new TestRunScheduler());
        Test.stopTest();
    }
}