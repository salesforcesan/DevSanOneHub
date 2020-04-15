public class AttributeWrapper
{
    public String   name                {get; set;}
    public String   id                  {get; set;}
    public String   attributeName       {get; set;}
    public String   attributeValue      {get; set;}
    public String   attributeType       {get; set;}    
    public String   renderFreeText      {get; set;}
    public String   renderNumber        {get; set;}
    public String  renderFile          {get; set;}      
    public boolean  isVisible           {get; set;}
    public String imageName             {get; set;}  
    transient public Blob imageBody     {get; set;}  
    public Integer attributeOrder       {get; set;}
    public String attachmentId {get;set;}
    public String imageFlag {get;set;}    
    public boolean showChooseFile {
        get {
            return String.isNotBlank(this.attachmentId) ? false : true;
        }
    }
    public boolean isImage {
        get {
            return AttachmentAnalyzer.isImage(this.id, this.imageName, this.attributeType);
        }
    }

    public Boolean isAttachment {
        get {
            return AttachmentAnalyzer.isFile(this.id, this.attributeType);
        }
    }

    private void init(){
        renderFreeText='false';
        renderNumber='false';        
        imageFlag = '0';
        attachmentId = '';
        renderFile = 'false';
    }
    
    private AttributeWrapper() { }
    

    public void flushValue() {
        this.attributeValue = '';
        this.attachmentId = '';
        this.imageName = '';
    }

    public static AttributeWrapper newInstance(ServiceAttribute__c sa, String pattributeValue) {
        return new AttributeWrapper(sa, pattributeValue);
    }

    private AttributeWrapper(ServiceAttribute__c sa, String pattributeValue) 
    {
        init();

        name = sa.AttributeTitle__c;
        id = sa.Attribute__c;
        attributeValue = String.isNotBlank(pattributeValue) ? pattributeValue : '';
        attributeName =  sa.AttributeTitle__c;
        attributeType = sa.AttributeType__c;
        attributeOrder = Integer.ValueOf(sa.AttributeOrder__c);

        if (attributeType=='Text'){
             renderFreeText='true';
        }
        else if (attributeType=='Number'){
             renderNumber='true';
        }
        else if (attributeType=='Photo'){
             assignAttachment(attributeValue);
        } else if (attributeType=='File') {
            assignAttachment(attributeValue);
        }
    }

    
    private void assignAttachment(String attrValue) {
        renderFile= 'true';
        String[] arr = parseValue(attributeValue);
        imageFlag = arr[1];
        String id = arr[0];
        if (String.isNotBlank(id)){
            List<Attachment> atts = [SELECT Id, Name FROM Attachment WHERE Id=:id LIMIT 1];
            if (atts.size() > 0) {
                attachmentId = atts[0].Id;
                imageName = atts[0].Name;
            }
        }
    }
     
    private String[] parseValue(String attrValue) {
        String[] res = new String[2];
        if (String.isNotBlank(attrValue)) {
            String[] arr = attrValue.split('=');
            res[0] = arr[0];
            res[1] = arr.size() == 2 ? arr[1] : '0';
        } else {
            res[0] = '';
            res[1] = '0';
        }
        return res;
    }
}