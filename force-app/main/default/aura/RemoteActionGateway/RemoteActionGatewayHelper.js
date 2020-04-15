({
    NAMESPACE: 'c',
    ERROR_EVENT: 'e.c:ActionResponseErrorAppEvent',
    SUCCESS_EVENT: 'e.c:ActionResponseSuccessAppEvent',
    SUPPORTED_METHODS: ['get', 'search', 'filter', 'add', 'remove', 'modify'],

    handleRemoteRequest: function(cmp, evt) {
        var args = evt.getParam('arguments') || {};


        this._request(cmp,
            args.id +'',
            args.route + '',
            args.parameters || ''
        );
    },

    _request: function(cmp, eventId, route, params) {
        if(!eventId){
            console.log('The event id is required.');
        }

        var request, errors, className, method, action,
            routeItems = route.split('/');

        if (!route) {
            console.log('there is no route is specified');
            return;
        }

        function handleResponse(response) {
            var errors, state = response.getState();
            if (!cmp.isValid()) {
                console.log('The proxy component is out of scope with the route:' + route);
                return;
            }
            if ('SUCCESS' === state) {
                this._success(cmp, eventId, route, response.getReturnValue());
                return;
            }
            if ('ERROR' === state) {
                errors = response.getError();
                if (!!errors && !!errors[0] && !!errors[0].message) {
                    this._error(cmp, eventId, route, errors[0].message, params);
                } else {
                    this._error(cmp, eventId, route, 'The system run into an unknown error.', params)
                }
                return;
            }
            if ('INCOMPLETE' === state) {
                this._error(cmp, eventId, route, 'The system run into an incomplete state with the route:' + route, params);
                return;
            }
            console.log('The system run into an unknown state with the route:' + route);
        }

        if (routeItems.length < 2) {
            errors = [];
            errors.push('The remote action route is invalid:');
            errors.push(route);
            errors.push('. The route format is "className/actionType/(actionName)". The className must match the apex class model name, actionName (optional) must match the apex class model class method name and the supported action types are ');
            errors.push(this.SUPPORTED_METHODS.join(','));
            this._error(cmp, eventId, route, errors.join(' '), params);
            return;
        }

        className = routeItems[0];
        method = routeItems[1];
        action = (routeItems.length > 2) ? routeItems[2] : '';

        if (this.SUPPORTED_METHODS.indexOf(method.toLowerCase()) === -1) {
            errors = [];
            errors.push('The method is not supported. The supported methods are');
            errors.push(this.SUPPORTED_METHODS.join(','));
            this._error(cmp, eventId, route, errors.join(' '), params);
            return;
        }

        try {
            request = cmp.get(this.NAMESPACE + '.' + method);
            request.setParams({
                'query': JSON.stringify({
                    'class': className,
                    'action': action,
                    'body': params
                })
            });

            request.setCallback(this, handleResponse);
            $A.enqueueAction(request);
        } catch (ex) {
            console.log(ex);
            this._error(cmp, eventId, route, ex.toString(), params);
        }
    },

    _success: function(cmp, eventId, route, value) {
        var success = $A.get(this.SUCCESS_EVENT);
        success.setParams({
            'id': eventId,
            'route': route,
            'value': value
        });
        success.fire();
    },

    _error: function(cmp, eventId, route, message, params) {
        var error = $A.get(this.ERROR_EVENT);
        error.setParams({
            'id': eventId,
            'route': route,
            'parameters': params,
            'error': message
        });
        error.fire();
    }
})