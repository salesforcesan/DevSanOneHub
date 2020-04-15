({
	AppSettings: {
		action: "checkVisible"
	},

	genBody: function(cmp) {
		return {
			"recordId": cmp.get("v.recordId"),
			"objectName": cmp.get("v.object"),
			"rules":  cmp.get("v.rule")
		};
	},

	init: function(cmp, evt) {
		this.getDispatcher(cmp)
			.action(this.AppSettings.action)
			.body(this.genBody(cmp))
			.onSuccess(function(cmp, data) {
				cmp.set("v.isShown", data === 1);
			})
			.onError(this.onError)
			.run();
	}
})