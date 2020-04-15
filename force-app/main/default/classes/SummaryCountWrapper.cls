public class SummaryCountWrapper {
    
    @AuraEnabled
    public String Label{get;set;}
    
    @AuraEnabled
    public Integer Count{get;set;}
    
    public SummaryCountWrapper(String label, Integer count) {
        this.Label = label;
        this.Count = count;
    }
}