({

    onInit: function(cmp, evt, h)
    {
        h.loadLocationStateData(cmp, evt, h);
    },


    onChanged: function(cmp, evt, h){
      h.changed(cmp, evt);
  },
  
})