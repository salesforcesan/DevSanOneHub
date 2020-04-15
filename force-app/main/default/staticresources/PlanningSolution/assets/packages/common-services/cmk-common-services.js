/* global Visualforce */
/* global angular */
/* Crossmark commmon service API definition
 * instruction: for each visual page, you need to copy the following codes into <script> tag inside the HTML <head> section

      //todo: before deploy this file, please modify salesforce cloud related settings and copy this into the header of visual page
  
  angular.module("cmk.web.context", [])
    .factory("cmkWebContext", function() {
      return {
        staticResourcePath: "",
        applicationPath: "/assets",
        logonUserId: ""
      };
    });
  
*/

(function(A) {
    
    Date.prototype.isValid = function() {
        return Object.prototype.toString.call(this) === '[object Date]' && isFinite(this);
    };

    Date.prototype.format = function(pattern) {
        return pattern === "/" ? [this.getMonth() + 1, this.getDate(), this.getFullYear()].join("/") : this.toISOString();
    };

    String.prototype.toDate = function() {
        var mon, year, date, arr;
        if (!this) {
            return null;
        }
        arr = this.split("/");
        if (arr.length !== 3) {
            return null;
        }
        year = parseInt(arr[2]);
        mon = parseInt(arr[0]) - 1;
        date = parseInt(arr[1])
        return new Date(year, mon, date, 0, 0, 0, 0);
    };

    A.module("cmk.system.async", [])
        .factory("cmkSystemAsync", ["$q", function($q) {

            function transformRecords(records, fields) {
                if (!!fields) {
                    var result = [];
                    records.forEach(function(record) {
                        var e = {};
                        _.forEach(fields, function(field) {
                            e[field] = record.get(field) || "-";
                        });
                        result[result.length] = e;
                    });
                    return result;
                } else {
                    return records;
                }
            }

            function Async() {}

            Async.prototype.call = function(method, args, fields) {
                var defer = $q.defer();
                if (!!args) {
                    method(args, function(err, records, event) {
                        if (err) {
                            defer.reject(err);
                        } else {
                            if (!!event) {
                                defer.resolve(transformRecords(records, fields), event);
                            } else {
                                defer.resolve(transformRecords(records, fields));
                            }
                        }
                    });
                } else {
                    method(function(err, records, event) {
                        var data;
                        if (err) {
                            defer.reject(err);
                        } else {
                            data = (fields.length === 0) ? records[0] : transformRecords(records, fields);
                            if (!!event) {
                                defer.resolve(data);
                            } else {
                                defer.resolve(data, event);
                            }
                        }
                    });
                }

                return defer.promise;
            };

            Async.prototype.remoting = function(action, args) {
                var defer = $q.defer();

                function handleCallback(result, event) {
                    if (event.status) {
                        defer.resolve(result);
                    } else if (event.type === 'exception') {
                        defer.reject([event.message, event.where].join("\r\n"));
                    } else {
                        defer.reject(event.message);
                    }
                }

                if (!!args) {
                    Visualforce.remoting.Manager.invokeAction(action, args, handleCallback);
                } else {
                    Visualforce.remoting.Manager.invokeAction(action, handleCallback);
                }

                return defer.promise;
            };

            return new Async();
        }]);

})(angular);
