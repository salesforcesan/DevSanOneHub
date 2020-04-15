({
  NODE_TOKEN_ID: 'ui-token',
  applySecurity: function(cmp) {
    //var div = cmp.find("ProjectService__c.Delete").getElement();
    //console.log(div);  
  	//console.log('----applySecurity----');
    //return;  
    var nodes = this._findUiConfigNodes(cmp);
    console.log('----result----')
    for (var n in nodes) {
        console.log(nodes[n].className || '');
        var arr = nodes[n].className.split(" ");
        console.log(arr[0]);
        var comp = cmp.find(arr[0]).getElement();
        console.log(comp);
        $A.util.addClass(comp, 'disablediv');
    }
    console.log(nodes);
  },  
  afterRender: function(cmp) {
    console.log('----afterRender----');
    var nodes = this._findUiConfigNodes(cmp);
    console.log('----result----')
    for (var n in nodes) {
    	console.log(nodes[n].className || '');
        var arr = nodes[n].className.split(" ");
        console.log(arr[0]);
        var comp = cmp.getConcreteComponent().find(arr[0]).getElement();
        console.log(comp);
        $A.util.addClass(comp, 'hide');
    }
    console.log(nodes);
  },
  _findUiConfigNodes: function(cmp) {
    var self = this;
    var root = cmp.getConcreteComponent();
    var children = root.getElements();
    var result = [];
    for (var i in children) {
      self._crawlChildren(children[i], result, self);
    }
    return result;
  },

  _crawlChildren: function(node, houses, self) {
      try
      {
      	if (node.className && node.className.indexOf(self.NODE_TOKEN_ID) != -1) {
          houses.push(node);
          return;
        }
          
      }
      catch (ex)
      {
          
      }
          
      var nodes = node.childNodes || [];
      for (var idx in nodes) {
	      self._crawlChildren(nodes[idx], houses, self);
      }
  }
})