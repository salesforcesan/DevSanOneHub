global without sharing class ResponseBuilder {
    private List<String> Errors {get; private set;}
    private List<String> Warnings {get; private set;}
    private Map<String, Object> Elements {get; private set;}

    public ResponseBuilder() {
        this.Errors = new List<String>();
        this.Warnings = new List<String>();
        this.Elements = new Map<String, Object>();
    }

    public void addElement(String key, Object value) {
        List<Object> vals;
        if (this.Elements.containsKey(key)) {
            vals = (List<Object>)this.Elements.get(key);
        } else {
            vals = new List<Object>();
        }

        vals.add(value);
        this.Elements.put(key, vals);
    }

    public void addElements(String key, List<Object> values) {
        List<Object> vals;
        if (values == null || values.isEmpty()) {return;}

        if (this.Elements.containsKey(key)) {
            vals = (List<Object>)this.Elements.get(key);
        } else {
            vals = new List<Object>();
        }

        for(Object obj: values) {
            vals.add(obj);
        }

        this.Elements.put(key, vals);
    }

    public void addError(String msg) {
        this.Errors.add(msg);
    }

    public void addAllErrors(List<String> msgs) {
        if (msgs == null || msgs.isEmpty()) {return;}
        this.Errors.addAll(msgs);
    }

    public void addWarn(String msg) {
        this.Warnings.add(msg);
    }

    public void addAllWarns(List<String> msgs) {
        if (msgs == null || msgs.isEmpty()) {return;}
        this.Warnings.addAll(msgs);
    }

    public Boolean hasError() {
        return !this.Errors.isEmpty();
    }

    public Boolean hasWarning() {
        return !this.Warnings.isEmpty();
    }

    public Map<String, Object> build() {
        Map<String, Object> result = new Map<String, Object>();

        String status = CONSTANTS.STATUS_OK;
        if (this.hasWarning()) {
            status = CONSTANTS.STATUS_WARN;
            result.put('warnings', this.Warnings);
        }

        if (this.hasError()) {
            status = CONSTANTS.STATUS_ERROR;
            result.put('errors', this.Errors);
        }

        result.put('status', status);
        
        if (!this.Elements.isEmpty()) {
            result.putAll(this.Elements);
        }
        
        return result;
    }
}