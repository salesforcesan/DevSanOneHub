global class ReservationRequestWrapper {
    @AuraEnabled
    global string LocationId{get; set;}
    @AuraEnabled
    global string LocationNumber{get; set;}
    @AuraEnabled
    global Decimal LocationLatitude{get; set;}
    @AuraEnabled
    global Decimal LocationLongitude{get; set;}
    @AuraEnabled
    global string LocationName{get; set;}
    @AuraEnabled
    global string LocationCity{get; set;}
    @AuraEnabled
    global string LocationState{get; set;}
    @AuraEnabled
    global string LocationAddress{get; set;}
    @AuraEnabled
    global string LocationZip{get; set;}
    @AuraEnabled
    global string ReservationDate{get; set;}
    @AuraEnabled
    global string ReservationErrorCode{get; set;}
    @AuraEnabled
    global string ReservationErrorMessage{get; set;}
    @AuraEnabled
    global string ReservationWarningMessage{get; set;}
    @AuraEnabled
    global string Status{get; set;}
    @AuraEnabled
    global string AvailableCapacity{get; set;}
    @AuraEnabled
    global string Proximity{get; set;}
    @AuraEnabled
    global boolean CapacityOverride{get; set;}
    @AuraEnabled
    global boolean IsResolvable{get; set;}
    @AuraEnabled
    global boolean IsOverridable{get; set;}
    @AuraEnabled
    global List<string> ReservationErrorMessageList{get; set;}
    @AuraEnabled
    global List<string> ReservationWarningMessageList{get; set;}
    @AuraEnabled
    global Integer NumberofErrorMessages{get; set;}
    @AuraEnabled
    global Integer NumberofWarningMessages{get; set;}
    @AuraEnabled
    global Integer RequestedLocationCount{get; set;}
    
    
    
    
    global ReservationRequestWrapper()
    {
        LocationId = '';
        LocationNumber = '';
        LocationLatitude = 0;
        LocationLongitude = 0;
        LocationName = '';
        LocationCity = '';
        LocationState = '';
        LocationAddress = '';
        LocationZip = '';
        RequestedLocationCount= 0;
        ReservationDate = '';
        ReservationErrorCode = '';
        ReservationErrorMessage = '';
		ReservationWarningMessage = '';        
        Status = '';
        AvailableCapacity= '';
        Proximity = '';
        CapacityOverride = false;
        IsResolvable = true;
        IsOverridable = true;
        ReservationErrorMessageList = new List<string>();
        ReservationWarningMessageList = new List<string>();
        NumberofErrorMessages = 0;
        NumberofWarningMessages = 0;
    }
}