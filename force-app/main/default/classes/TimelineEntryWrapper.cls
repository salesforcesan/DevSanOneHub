public class TimelineEntryWrapper{     
    @AuraEnabled
    public String PhotoURL {get; set;}
    
    @AuraEnabled
    public String EventIconName {get; set;}
    
    @AuraEnabled
    public Boolean IsEventIcon {get; set;}
            
    @AuraEnabled
    public String TimelineEntryTitle {get; set;}
            
    @AuraEnabled
    public String TimelineEntryDate {get; set;}
          
}