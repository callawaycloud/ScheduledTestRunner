public class TestRunEmailController {
    public Id testRunId { get; set; }
    public String getbaseURL() {
        String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
        return baseURL;
    }
    public List<Test_Run_Method_Result__c> getMethodResults() {
        List<Test_Run_Method_Result__c> results;
        results = [
            SELECT Id, Name, Method_Name__c, Message__c, First_Failure__c, Run_Time__c
            FROM Test_Run_Method_Result__c
            WHERE Test_Run__c = :testRunId AND Method_Pass__c = false
        ];
        List<Test_Run_Method_Result__c> methodResults = new List<Test_Run_Method_Result__c>();
        for (Test_Run_Method_Result__c r : results) {
            if (r.First_Failure__c.date() == Date.today()) {
                methodResults.add(r);
            }
        }
        return methodResults;
    }
}