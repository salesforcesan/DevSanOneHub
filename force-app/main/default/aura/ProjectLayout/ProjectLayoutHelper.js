({
  init: function(cmp, evt) {
    this._setReturnComponent(cmp);
    this.cGetProject(cmp);
  },

  _setReturnComponent: function(cmp) {
    var name = this._getTargetName();
    console.log(name);
  },

  _getTargetName: function() {
    var hash, name, tag = 'slideDevName=';
    hash = location.hash || '';
    if (!hash) {
      return 0;
    }
    name = hash.indexOf(tag) !== -1 ?
      hash.substr(hash.indexOf(tag), tag.length) : '';
    if (!name) {
      return 0;
    }
    return name.indexOf('&') !== -1 ?
      name.substr(0, name.indexOf('&')) : name;
  },

  cGetProject: function(component) {

    var recordId = component.get("v.recordId");
    var action = component.get("c.GetProject");
    action.setParams({ "recordId": recordId });

    var self = this;
    action.setCallback(self, function(result) {
      var state = result.getState();
      if (state === "SUCCESS") {
        var project = result.getReturnValue();
        component.set("v.project", project);
        component.set("v.renderReady", "true");
      }
    });
    $A.enqueueAction(action);

  }

})