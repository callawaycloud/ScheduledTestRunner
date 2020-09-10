public class TestRunEmailController {
    List<Test_Run_Method_Result__c> queryResults;
    public Id testRunId { get; set; }
    public String getbaseURL() {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return baseURL;
    }

    public Map<String, List<Test_Run_Method_Result__c>> getFailureMap() {
        if (queryResults == null) {
            queryTestRun();
        }
        Map<String, List<Test_Run_Method_Result__c>> failureMap = new Map<String, List<Test_Run_Method_Result__c>>();
        for (Test_Run_Method_Result__c r : queryResults) {
            if (failureMap.containsKey(r.Name)) {
                failureMap.get(r.Name).add(r);
            } else {
                failureMap.put(r.Name, new List<Test_Run_Method_Result__c>{ r });
            }
        }
        return failureMap;
    }

    private void queryTestRun() {
        queryResults = [
            SELECT Id, Name, Method_Name__c, Message__c, First_Failure__c, New_Failure__c
            FROM Test_Run_Method_Result__c
            WHERE Test_Run__c = :testRunId AND Method_Pass__c = false
        ];
    }
}