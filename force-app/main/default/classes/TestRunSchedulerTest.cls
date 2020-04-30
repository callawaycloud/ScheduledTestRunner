/**
 *
 */
@isTest
private class TestRunSchedulerTest {
    // see all data necessary to we can query custom settings
    @isTest(SeeAllData=true)
    public static void testRunTest() {
        Test.StartTest();
        System.schedule('Automated Test Job [UNIT TESTING]', '0 0 23 * * ?', new TestRunScheduler());
        Test.stopTest();
    }
}