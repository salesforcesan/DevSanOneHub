public class AccountWrapper {
    
    @AuraEnabled
    public string OwnerName{get; set;}
    @AuraEnabled
    public string OwnerPhone{get; set;}
    @AuraEnabled
    public string Name{get; set;}
    @AuraEnabled
    public string Id{get; set;}
    @AuraEnabled
    public Boolean Approved{get; set;}
    @AuraEnabled
    public Boolean Selected{get; set;}
    
    Public AccountWrapper(){}
        
    	public AccountWrapper(Account AC){
            
            OwnerName = AC.Owner.Name;
            OwnerPhone = AC.Phone;
            Name = AC.Name;
            Id = AC.Id;
            Approved = AC.IsApproved__c;
            Selected = false;
        }        


}