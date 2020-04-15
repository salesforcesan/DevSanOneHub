global without sharing class ValidationResult {
    // valid values are "OK", "ERROR", "WARN"
    public String Status {get {
            if (this.Errors.isEmpty()) {
                return this.Warnings.isEmpty()
                    ? CONSTANTS.STATUS_OK
                    : CONSTANTS.STATUS_WARN;
            }
            return CONSTANTS.STATUS_ERROR;
        }
    }                      

    public List<String> Errors {get; set;}
    
    public List<String> Warnings {get; set;}

    private ValidationResult() {
        Errors = new List<String>();
        Warnings = new List<String>();
    }

    public static ValidationResult createInstance() {
        return new ValidationResult(); 
    }

    public void addError(String msg) {
        this.Errors.add(msg);
    }

    public void addWarning(String msg) {
        this.Warnings.add(msg);
    }
}