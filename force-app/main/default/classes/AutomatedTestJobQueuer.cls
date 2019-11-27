global with sharing class AutomatedTestJobQueuer implements schedulable {
    global void execute(SchedulableContext SC) {
        doExecute();
    }

    @future(callout=true)
    public static void doExecute() {
        enqueueUnitTests();
    }

    public static void createDaily4AMScheduledJob() {
        AutomatedTestJobQueuer atj = new AutomatedTestJobQueuer();
        string sch = '0 0 4 * * ?';
        system.schedule('Enqueue Unit Tests 4 AM', sch, atj);
    }

    /* Allows us to externally enqueue our unit tests. For example,
       whenever we check our code into source control, we could
       run our unit tests.
    */
    webService static void enqueueUnitTests() {
        enqueueTests();
    }

    // Enqueue all classes beginning with "Test".

    public static void enqueueTests() {
        /* The first thing you need to do is query the classes that contain
         the unit tests you want executed.

         In our org, our test classes are named "Test<Class_Name_Here>"
         so that all the test classes are grouped together in Eclipse.
         Change the where clause as necessary to query the desired classes.
       */
        ApexClass[] testClasses = [
            FIND '@isTest'
            IN ALL FIELDS
            RETURNING ApexClass(Id, Name)
        ][0];
        //    ApexClass[] testClasses =
        //    ApexClass[] testClasses =
        //    ApexClass[] testClasses =
        //      [SELECT Id,
        //              Name
        //         FROM ApexClass
        //         WHERE Name LIKE 'Test%' OR Name LIKE '%Test'];

        Integer testClassCnt = testClasses != null ? testClasses.size() : 0;

        system.debug('   enqueueTests::testClassCnt ' + testClassCnt);

        if (testClassCnt > 0) {
            /*
             Insertion of the ApexTestQueueItem causes the unit tests to be
             executed. Since they're asynchronous, the apex async job id
             needs to be stored somewhere so we can process the test results
             when the job is complete.
          */
            ApexTestQueueItem[] queueItems = new List<ApexTestQueueItem>();

            for (ApexClass testClass : testClasses) {
                system.debug('   enqueueTests::testClass ' + testClass);

                queueItems.add(
                    new ApexTestQueueItem(ApexClassId = testClass.Id)
                );
            }

            insert queueItems;

            // Get the job ID of the first queue item returned.

            ApexTestQueueItem item = [
                SELECT ParentJobId
                FROM ApexTestQueueItem
                WHERE Id = :queueItems[0].Id
                LIMIT 1
            ];

            Scheduled_Test_Result__c atq = new Scheduled_Test_Result__c(
                Job_Id__c = item.parentjobid
            );

            insert atq;
        }
    }
}
