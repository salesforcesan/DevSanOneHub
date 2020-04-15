({
	pSelected: function(component){
        var projectType = component.get("v.ptype");
        console.log('helper method=' + projectType.Name);
         //var src = event.getSource();
        //var selected = src.get('ptype.Id');
        //var ptype1 = component.find('selectedProjectType');
        //component.set("v.projectTypes",selected);
        //console.log("selected value=" + selected);
    }
})