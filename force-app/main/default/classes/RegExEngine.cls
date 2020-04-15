global without sharing class RegExEngine {
    private Pattern patternInstance;
    private static Map<String, RegExEngine> instances;

    global static final string UrlPattern = '^(http://|https://)?(www.)?([a-zA-Z0-9]+).[a-zA-Z0-9]*.[a-z]{3}.?([a-z]+)?';
    global static final String DatePattern = '\\d\\d\\d\\d-\\d\\d?-\\d\\d?|\\d\\d?\\/\\d\\d?\\/\\d\\d\\d\\d';
    global static final String NumberPattern = '^-?[0-9]+$';
    global static final String TimePattern = '(1[0-2]|0?[1-9]):[0-5][0-9] ([AaPp][Mm])';

    private RegExEngine(string patternString) {
        this.patternInstance = Pattern.compile(patternString);
    }

    global static RegExEngine createInstance(string patternString) {
        return new RegExEngine(patternString);
    }

    global boolean matches(string inputString) {
        try {
            return this.patternInstance.matcher(inputString).find();
        } catch (Exception ex) {
            return false;
        }

    }

    global static RegExEngine getInstance(String name, String patternString) {
        if (instances == null) {
            instances = new Map<String, RegExEngine>();
            return addNewInstance(name, patternString);
        }
        if (instances.containsKey(name)) {
            return (RegExEngine) instances.get(name);
        }
        return addNewInstance(name,patternString);
    }

    static RegExEngine addNewInstance(String name,String patternString){
        RegExEngine engine = RegExEngine.createInstance(patternString);
        instances.put(name, engine);
        return engine;
    }   
}