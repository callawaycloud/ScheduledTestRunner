public class TestRunEmailController {
    List<Test_Run_Method_Result__c> queryResults;
    public Id testRunId { get; set; }
    public String getbaseURL() {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return baseURL;
    }

    public Map<String, List<Test_Run_Method_Result__c>> getFirstFailureMap() {
        if (queryResults == null) {
            queryTestRun();
        }
        Map<String, List<Test_Run_Method_Result__c>> firstFailureMap = new Map<String, List<Test_Run_Method_Result__c>>();
        for (Test_Run_Method_Result__c r : queryResults) {
            if (r.First_Failure__c.date() == Date.today()) {
                if (firstFailureMap.containsKey(r.Name)) {
                    firstFailureMap.get(r.Name).add(r);
                } else {
                    firstFailureMap.put(r.Name, new List<Test_Run_Method_Result__c>{ r });
                }
            }
        }
        return firstFailureMap;
    }
    public Map<String, List<Test_Run_Method_Result__c>> getRemainingFailureMap() {
        if (queryResults == null) {
            queryTestRun();
        }
        Map<String, List<Test_Run_Method_Result__c>> remainingFailureMap = new Map<String, List<Test_Run_Method_Result__c>>();
        for (Test_Run_Method_Result__c r : queryResults) {
            if (r.First_Failure__c.date() != Date.today()) {
                if (remainingFailureMap.containsKey(r.Name)) {
                    remainingFailureMap.get(r.Name).add(r);
                } else {
                    remainingFailureMap.put(r.Name, new List<Test_Run_Method_Result__c>{ r });
                }
            }
        }
        return remainingFailureMap;
    }

    private void queryTestRun() {
        queryResults = [
            SELECT Id, Name, Method_Name__c, Message__c, First_Failure__c
            FROM Test_Run_Method_Result__c
            WHERE Test_Run__c = :testRunId AND Method_Pass__c = false
        ];
    }
}