({
    setErrorMessage: function(component, response){
         var errors=response.getError();
         if(errors[0] && errors[0].message){
               component.set("v.message",errors[0].message);
         }
    },
     _notify: function(cmp, msg, type, autoHide, duration) {
    cmp.find('notification').show(msg, type, autoHide, duration);
  }
})