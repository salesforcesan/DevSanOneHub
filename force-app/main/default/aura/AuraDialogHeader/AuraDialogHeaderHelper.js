({
  init: function(cmp) {
    var marginGap = cmp.get("v.marginGap");
    if (!!marginGap) {
      cmp.set(
        "v.style",
        ["margin-left:", marginGap, ";margin-right:", marginGap, ";"].join("")
      );
      cmp.set("v.hasGap", true);
    }
  }
});