/**
 *
 */
@isTest
private class AutomatedTestingJobTest {
    // see all data necessary to we can query custom settings
    @isTest(SeeAllData=true)
    public static void testQueuer() {
        Test.StartTest();
        System.schedule('Automated Test Job [UNIT TESTING]', '0 0 23 * * ?', new AutomatedTestingJob());
        Test.stopTest();
    }
}
