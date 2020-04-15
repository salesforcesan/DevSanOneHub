public class LocaleManager {
    private Map<String,String> dictionary;
    
    public static String ENGLISH_CODE = 'ENG';
    public static String FRENCH_CODE = 'FRA';

    public String VariantId {get; private set;}
    public String LanguageCode {get; private set;}
    public Map<String,String> Labels {
        get {
            return dictionary;
        }
    }
    public Boolean IsEnglish {get {
        return this.LanguageCode == LocaleManager.ENGLISH_CODE ? true : false;  
        }}

    public static LocaleManager newInstance() {
        return new LocaleManager();
    }

    public static LocaleManager newInstance(String languageCode) {
        return new LocaleManager(languageCode);
    }

    private LocaleManager() {
        this.LanguageCode = LocaleManager.ENGLISH_CODE;
        this.Init();
    }

    private LocaleManager(String languageCode) {
        this.LanguageCode = String.isNotBlank(languageCode) ? languageCode.toUpperCase() : LocaleManager.ENGLISH_CODE;
        this.init();    
    }

    private void Init() {
        dictionary = new Map<String,String>();
        if (this.LanguageCode == LocaleManager.FRENCH_CODE) {
            InitLanguageId('French');
            initEventManualVariant([SELECT Name, FraLabel__c FROM JobManualVariant__c],'FraLabel__c');
        } else {
            this.VariantId = '';
            initEventManualVariant([SELECT Name, EngLabel__c FROM JobManualVariant__c],'EngLabel__c');
        }
    }

    private void InitLanguageId(String name) {
        List<Variant__c> langs = [SELECT Id FROM Variant__c WHERE Language__r.Name=:name LIMIT 1];
        this.VariantId = langs.size() > 0 ? String.valueOf(langs[0].Id): '';
    }

    private void initEventManualVariant(List<JobManualVariant__c> items, String label) {
        String key;
        String value;

        for(JobManualVariant__c e: items) {
            key = String.valueOf(e.Name);
            value = String.valueOf(e.get(label));

            if (dictionary.containsKey(key)) { dictionary.remove(key);}
            dictionary.put(key, value);
        }
    }
}