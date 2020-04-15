global class ReservationWrapper {
    @AuraEnabled
    global string Id{get; set;}
    @AuraEnabled
    global string Name{get; set;}
    @AuraEnabled
    global string CancelReason{get; set;}
    @AuraEnabled
    global string CancelReasonComment{get; set;}
    @AuraEnabled
    global string ExpirationDate{get; set;}
    @AuraEnabled
    global string Status{get; set;}
    @AuraEnabled
    global Integer RequestedLocationCount{get; set;}
    @AuraEnabled
    global string RequestedDate{get; set;}
    @AuraEnabled
    global string RequestedService{get; set;}
    
    
    global ReservationWrapper()
    {
        Id = '';
        Name = '';
        CancelReason = '';
        CancelReasonComment = '';
        Status = '';
        ExpirationDate='';
        RequestedLocationCount = 0;
        RequestedDate = '';
        RequestedService = '';
    }
}