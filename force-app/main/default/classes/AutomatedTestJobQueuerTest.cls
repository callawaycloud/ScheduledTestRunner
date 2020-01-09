/**
 *
 */
@isTest
private class AutomatedTestJobQueuerTest {
    // see all data necessary to we can query custom settings
    @isTest(SeeAllData=true)
    public static void testQueuer() {
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_SOSL.htm
        Test.setFixedSearchResults(new List<Id>{ '01p3A000001LkX5' }); // ApexClass result type Id for search queries

        Test.StartTest();
        System.schedule('Automated Test Job Queuer [UNIT TESTING]', '0 0 23 * * ?', new AutomatedTestJobQueuer());
        Test.stopTest();
    }
}