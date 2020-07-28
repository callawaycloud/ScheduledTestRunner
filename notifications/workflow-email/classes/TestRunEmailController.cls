public class TestRunEmailController {
    public Id testRunId { get; set; }
    public String getbaseURL() {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return baseURL;
    }
    public Map<String, List<Test_Run_Method_Result__c>> getMethodResults() {
        List<Test_Run_Method_Result__c> results = [
            SELECT Id, Name, Method_Name__c, Message__c, First_Failure__c
            FROM Test_Run_Method_Result__c
            WHERE Test_Run__c = :testRunId AND Method_Pass__c = false
        ];
        Map<String, List<Test_Run_Method_Result__c>> methodResults = new Map<String, List<Test_Run_Method_Result__c>>();
        for (Test_Run_Method_Result__c r : results) {
            if (r.First_Failure__c.date() == Date.today()) {
                if (methodResults.containsKey(r.Name)) {
                    methodResults.get(r.Name).add(r);
                } else {
                    methodResults.put(r.Name, new List<Test_Run_Method_Result__c>{ r });
                }
            }
        }
        return methodResults;
    }

    public List<String> getMethodKeys() {
        List<String> methodKeys = new List<String>(getMethodResults().keySet());
        return methodKeys;
    }
}