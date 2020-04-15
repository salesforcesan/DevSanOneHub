({
    doInit : function(cmp,e,h) { 
        h.init(cmp); 
    },
    
    submitProject: function(cmp,e,h) {        
        h.notifyProjectUpdate(cmp,e,h);
    } 
})