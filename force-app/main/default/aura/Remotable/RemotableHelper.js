({
  InvalidImage:
    "data:image/svg+xml;base64,PHN2ZyB2ZXJzaW9uPSIxLjEiIGlkPSJMYXllcl8xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiB4PSIwcHgiIHk9IjBweCIKCSB2aWV3Qm94PSIwIDAgODAgMTIwIiBzdHlsZT0iZW5hYmxlLWJhY2tncm91bmQ6bmV3IDAgMCA4MCAxMjA7IiB4bWw6c3BhY2U9InByZXNlcnZlIj4KPGc+Cgk8cGF0aCBzdHlsZT0iZmlsbDojYzIzOTM0IiBkPSJNNTYuNCw3Ny45TDQxLjgsNjUuMUwyNC42LDc1LjRsLTExLjMtOS43TDAsNzMuMVYxMjBoODBWNzUuM0w2Ni45LDY3TDU2LjQsNzcuOXogTTc1LjgsNzguMnYzN0g0LjN2LTM5bDguNi00LjdsMTEuMyw5LjcKCQlsMTcuMS0xMC40bDE1LjMsMTMuNEw2Ny41LDczTDc1LjgsNzguMnoiLz4KCTxwYXRoIHN0eWxlPSJmaWxsOiNjMjM5MzQiIGQ9Ik02MC40LDBIMHY2MC4zbDEzLjctNi4xbDEwLjksOS40bDE4LjgtMTIuN2wxMi43LDEzbDkuOS05LjdsMTQsNy4xVjIyLjFMNjAuNCwweiBNNTguNyw0LjlsMTYuNCwxOC41SDU4LjdWNC45egoJCSBNNjUuMyw0OC41bC05LDguOUw0My45LDQ0LjlsLTE5LDEyLjlsLTEwLjUtOS4xTDQuMyw1My4xVjQuOWg1MC4ydjIzLjRoMjEuM3YyNS42TDY1LjMsNDguNXoiLz4KPC9nPgo8L3N2Zz4=",

  //need override if payload is not associated with onSuccess()
  onSuccess: function(cmp, response, action) {
    this._msgBox("success", "The success callback method is not implemented.");
  },

  //need override if payload is not attached with onError
  onError: function(cmp, error, action) {
    this._msgBox("error", error);
  },

  onDismissableSuccess: function(cmp, message) {
    this._msgBox("success", message, 0);
  },

  onDismissableError: function(cmp, error) {
    this.__msgBox("error", error, 0);
  },

  _print: function(data) {
    console.log(JSON.stringify(data));
  },

  getDispatcherPromise: function(cmp) {
    var dispatcher = this.getDispatcher(cmp);
    var me = {};
    me.className = function(c) {
      dispatcher.className = c;
      return me;
    };

    return me;
  },

  getDispatcher: function(cmp) {
    var className,
      _action,
      _body,
      successCallback,
      errorCallback,
      finallyCallback,
      self = this,
      me = {};

    me.className = function(c) {
      className = c;
      return me;
    };

    me.action = function(a) {
      _action = a;
      return me;
    };

    me.body = function(b) {
      _body = b;
      return me;
    };

    me.onSuccess = function(f) {
      successCallback = f;
      return me;
    };

    me.onError = function(f) {
      errorCallback = f;
      return me;
    };

    me.onFinally = function(f) {
      finallyCallback = f;
      return me;
    };

    me.run = function(body) {
      var data = body;
      if (!data) {
        if (!!className && !!_action) {
          data = {
            query: JSON.stringify({
              class: className,
              action: _action,
              body: _body
            })
          };
        } else {
          data = _body;
        }
      }

      var payload = {
        action: _action,
        data: data,
        onSuccess: successCallback,
        onError: !!errorCallback ? errorCallback : 0,
        onFinally: !!finallyCallback ? finallyCallback : 0
      };
      self.dispatch(cmp, payload);
    };

    return me;
  },

  dispatch: function(cmp, payload) {
    var request,
      errors,
      state,
      self = this,
      cmp = cmp.getConcreteComponent(),
      successCallback = function(cmp, response) {
        if (!!payload.onSuccess) {
          payload.onSuccess.call(self, cmp, response);
        } else {
          self.onSuccess.call(self, cmp, response, payload.action);
        }
      },
      failureCallback = function(cmp, error) {
        if (!!payload.onError) {
          payload.onError.call(self, cmp, error);
        } else {
          self.onError.call(self, cmp, error, payload.action);
        }
      },
      finallyCallback = function(cmp) {
        !!payload.onFinally && payload.onFinally(cmp);
      };

    function handleResponse(response) {
      state = response.getState();
      if (!cmp.isValid()) {
        self._msgBox("error", "The component is out of scope.");
        return;
      }
      switch (state) {
        case "SUCCESS":
          successCallback(cmp, response.getReturnValue());
          break;
        case "ERROR":
          errors = response.getError();
          if (!!errors && !!errors[0] && !!errors[0].message) {
            failureCallback(cmp, errors[0].message);
          } else {
            failureCallback(cmp, "The system runs into an error.");
          }
          break;
        case "INCOMPLETE":
          failureCallback(cmp, "The system runs into an incomplete state.");
          break;
        default:
          failureCallback(cmp, "The system runs into an unknown state.");
          break;
      }
      finallyCallback(cmp);
    }

    try {
      request = cmp.get("c." + payload.action);
      request.setParams(payload.data);
      if (!!payload.storable) {
        request.setStorable();
      }
      request.setCallback(self, handleResponse);
      $A.enqueueAction(request);
    } catch (ex) {
      console.log(ex);
      failureCallback("error", ex.message);
    }
  },

  _msgBox: function(msgType, msg) {
    this.__msgBox(msgType, msg, msgType === "error" ? 1 : 0);
  },

  _msgBoxWithTitle: function(msgType, msg, title) {
    this.__msgBoxWithTitle(msgType, msg, title, msgType === "error" ? 1 : 0);
  },

  __msgBox: function(msgType, msg, sticky) {
    var evt = $A.get("e.force:showToast");
    evt.setParams({
      message: msg,
      type: msgType,
      mode: !!sticky ? "sticky" : "dismissible"
    });
    evt.fire();
  },

  __msgBoxWithTitle: function(msgType, msg, title, sticky) {
    var evt = $A.get("e.force:showToast");
    evt.setParams({
      title: title,
      message: msg,
      type: msgType,
      mode: !!sticky ? "sticky" : "dismissible"
    });
    evt.fire();
  },

  _async: function(cmp, callback, duration) {
    if (!callback) {
      return;
    }
    var self = this;
    duration = duration || 200;
    var id = window.setTimeout(
      $A.getCallback(function() {
        window.clearTimeout(id);
        if (cmp.isValid()) {
          callback.call(self, cmp);
        }
      }),
      duration
    );

    return id;
  },

  _throttle: function(cmp, duration, context) {
    var self = this;
    var lock = cmp.get("v.lock");
    var firstTime = cmp.get("v.firstTimeLock");

    function onTimeout(cmp) {
      var msg = cmp.getEvent("onLoadNextPage");
      if (!!context) {
        msg.setParams({ context: context });
      }
      msg.fire();
      cmp.set("v.lock", false);
    }

    if (!!lock) {
      return;
    }
    cmp.set("v.lock", true);

    if (!!firstTime) {
      cmp.set("v.firstTimeLock", false);
      duration = 0;
    }

    this._async(cmp, onTimeout, duration);
  },

  _debounce: function(cmp, callback, duration) {
    var wait = duration || 250,
      self = this,
      timeoutId = cmp.get("v.timeoutId");

    function wrapCallback(cmp) {
      if (!!callback) {
        callback.call(self, cmp);
      }
      cmp.set("v.timeoutId", 0);
    }

    if (!!timeoutId) {
      window.clearTimeout(timeoutId);
    }

    timeoutId = this._async(cmp, wrapCallback, wait);
    cmp.set("v.timeoutId", timeoutId);
  }
});