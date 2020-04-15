global class SerachProjectInvoiceWrapper{
        
    @AuraEnabled
    public string InvoiceId {get; set;}
    
    @AuraEnabled
    public string Account {get; set;}
    @AuraEnabled
    public string BillToContact {get; set;}
    @AuraEnabled
    public string LawsonCompnanyCode {get; set;}
    @AuraEnabled
    public string InvoiceType {get; set;}
    @AuraEnabled
    public string FilterDateRange {get; set;}
    @AuraEnabled
    public string FromDate {get; set;}
    @AuraEnabled
    public string ToDate {get; set;}
    @AuraEnabled
    public string PONumber {get; set;}        
    @AuraEnabled
    public string ProjectNumber {get; set;}       
    @AuraEnabled
    public string ProjectName {get; set;}    
	@AuraEnabled
    public string InvoiceToInclude {get; set;}    
}