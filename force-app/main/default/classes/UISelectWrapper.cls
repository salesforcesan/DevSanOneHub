public class UISelectWrapper {
    
    
		@AuraEnabled    
    	public String Label {get;set;}
    
 		@AuraEnabled    
        public String Text {get; set;}
        
        public UISelectWrapper (String label, String text)
        {
            this.Label = label;
            this.Text = text;
        }
        
        public UISelectWrapper () {}
    
    }