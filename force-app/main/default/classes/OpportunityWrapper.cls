public class OpportunityWrapper {
    @AuraEnabled
    public string Id{get; set;}     
    @AuraEnabled
    public String ReservationId{get; set;}
    @AuraEnabled
    public String ReservationName{get; set;}
    public OpportunityWrapper(String resID) {
      
       this.ReservationId = resID;
       
   }

}