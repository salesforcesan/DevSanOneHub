({
	onChange: function(cmp, evt) {
		var changeValue = evt.getParam("value");
		cmp.set("v.value", changeValue);
	}
})