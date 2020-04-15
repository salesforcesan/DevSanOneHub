({   
	doInit: function(cmp, event, helper) {
       helper.getProjectService(cmp);

	},    
    toggleAccAll : function(component, event, helper) {
        var acc = document.querySelectorAll('.accordion'), i;
        for (var i = 0; i < acc.length; i ++) {
          acc[i].nextElementSibling.classList.toggle("show"); 
        }
    },
    
     toggleAcc : function(component) {
        var acc = document.querySelector("#accordion");
                acc.classList.toggle("active");
                acc.nextElementSibling.classList.toggle("show");
    }
    
    /*
    toggleAcc : function(component) {
        var acc = document.querySelectorAll(".accordion"), i;
        for (i = 0; i < acc.length; i++) {
            acc[i].onclick = function(){
                this.classList.toggle("active");
                this.nextElementSibling.classList.toggle("show");
            }
        }
    }
    */
   
})