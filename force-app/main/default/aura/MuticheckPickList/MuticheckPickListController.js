({
    handleClick : function(component, event, helper)
    {
        var menu = component.find("menulist");
        $A.util.toggleClass(menu, "slds-is-open"); 
    },
    statusClick:  function(cmp, event, helper)
    {
        var cmpId = event.currentTarget.id;
        var status = cmp.get('v.multiStatues');
        var element = document.getElementById(cmpId);
        if(element.getAttribute('class') === 'slds-is-selected')
        {
            $A.util.removeClass(element, 'slds-is-selected'); 
            
        }
        else
        {
            $A.util.addClass(element, 'slds-is-selected'); 
        }
        parent = element.parentNode;
        var items = parent.getElementsByTagName("li");
        var sum = 0;
        for (var i = 0; i < items.length; i++) {
            if(items[i].getAttribute('class')==='slds-is-selected')
            {
                sum = sum + 1;
                
                if(status.indexOf(items[i].getAttribute('id')) === -1)
                {
                    status.push(items[i].getAttribute('id'));
                }
                
            }
            else
            {
                
                if(status.indexOf(items[i].getAttribute('id')) != -1) {
                    status.splice(status.indexOf(items[i].getAttribute('id')),1);
                    
                }
            }
            
        }
        
        
        var searchLst = cmp.find("searchDrpLst").getElement();
        searchLst.value = sum + " selected";
        
        
    },
    
    blurClick: function(cmp, event, helper) {
        var cmpId = event.currentTarget.id;
        var toBlur = document.getElementById(cmpId);
        if(toBlur.getAttribute('class') === 'slds-is-selected')
        {
            $A.util.removeClass(toBlur, 'slds-is-selected'); 
            
        }
    },
    
    handleUnCheckAll: function(cmp, event)
    {
       var items = document.querySelectorAll('.slds-is-selected');
              
        for (var i = 0; i < items.length; i++) {
           
                    
            if(items[i].getAttribute('class')==='slds-is-selected')
            {
             
                  $A.util.removeClass(items[i], 'slds-is-selected'); 
                
            }
            
            
        }
        var searchLst = cmp.find("searchDrpLst").getElement();
        searchLst.value = 0 + " selected";
        
              
    }
    
})