public class TestRunEmailController {
    List<Test_Run_Method_Result__c> queryResults;
    public Id testRunId { get; set; }
    public String getbaseURL() {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return baseURL;
    }

    public Map<String, List<Test_Run_Method_Result__c>> getFirstFailureMap() {
        Map<String, List<Test_Run_Method_Result__c>> firstFailureMap = getMethodResults(true);
        return firstFailureMap;
    }
    public Map<String, List<Test_Run_Method_Result__c>> getRemainingFailureMap() {
        Map<String, List<Test_Run_Method_Result__c>> remainingFailureMap = getMethodResults(false);
        return remainingFailureMap;
    }

    private Map<String, List<Test_Run_Method_Result__c>> getMethodResults(Boolean firstFailure) {
        queryResults = [
            SELECT Id, Name, Method_Name__c, Message__c, First_Failure__c
            FROM Test_Run_Method_Result__c
            WHERE Test_Run__c = :testRunId AND Method_Pass__c = false
        ];
        Map<String, List<Test_Run_Method_Result__c>> firstFailureMap = new Map<String, List<Test_Run_Method_Result__c>>();
        Map<String, List<Test_Run_Method_Result__c>> remainingFailMap = new Map<String, List<Test_Run_Method_Result__c>>();

        for (Test_Run_Method_Result__c r : queryResults) {
            if (r.First_Failure__c.date() == Date.today()) {
                if (firstFailureMap.containsKey(r.Name)) {
                    firstFailureMap.get(r.Name).add(r);
                } else {
                    firstFailureMap.put(r.Name, new List<Test_Run_Method_Result__c>{ r });
                }
            } else {
                if (remainingFailMap.containsKey(r.Name)) {
                    remainingFailMap.get(r.Name).add(r);
                } else {
                    remainingFailMap.put(r.Name, new List<Test_Run_Method_Result__c>{ r });
                }
            }
        }
        if (firstFailure) {
            return firstFailureMap;
        }
        return remainingFailMap;
    }

    public List<String> getFirstFailureKeys() {
        List<String> firstFailureKeys = new List<String>(getFirstFailureMap().keySet());
        return firstFailureKeys;
    }
    public List<String> getRemainingFailureKeys() {
        List<String> remainingFailureKeys = new List<String>(getRemainingFailureMap().keySet());
        return remainingFailureKeys;
    }
}