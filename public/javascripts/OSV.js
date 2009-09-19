var OSV = (function() {
    var changeables = [];
    var authenticity_token;
    var map;
    function addChangeable(c) {
        changeables.push(c);
    }
    function removeChangeable(c) {
        var nc = [];
        for( var i = 0, l = changeables.length; i < l; ++i ) {
            if( changeables[i] != c )
                nc.push( changeables[i] );
        }
        changeables = nc;
    }
    function getAuthenticityToken() {
        return authenticity_token;
    }
    function readParams(paramsArr, paramsHash) {
        for( var i = 0, l = paramsArr.length; i < l; ++i ) {
            var bits = paramsArr[i].split('=');
            paramsHash[bits[0]] = decodeURIComponent(bits[1]);
        }
        return paramsHash;
    }
    function getPageParams() {
        var params = {};
        readParams(document.cookie.split('; '), params);
        readParams(window.location.search.substring(1).split('&'), params);
        OSV.getPageParams = function() {
            return params;
        }
        return OSV.getPageParams();
    }
    function getStartLocation() {
        var params = OSV.getPageParams();
        var zoom = params.zoom || 2;
        var pos;
        if( params.lat && params.lon ) {
            pos = new OpenLayers.LonLat(params.lon,params.lat);
        } else {
            pos = new OpenLayers.LonLat(0,0);
        }
        return { pos:pos,zoom:zoom };
    }
    function getURLBase() {
        return location.protocol+'//'+location.host;
    }
    function setupMapEventHandlers(new_map) {
        map = new_map;
        map.events.register("moveend", map, updateLocation);
        map.events.register("zoomend", map, updateLocation);
        map.events.register("changelayer", map, updateLocation);
    }
    function getMapCenter(map) {
        return map.getCenter().clone().transform(map.getProjectionObject(), epsg4326)
    }
    function getMapExtent(map) {
        return map.getExtent().clone().transform(map.getProjectionObject(), epsg4326);
    }
    function updateLocation() {
        var lonlat = getMapCenter(map);
        var zoom = map.getZoom();
        //var layers = getMapLayers();
        var expiry = new Date();
        expiry.setYear(expiry.getFullYear() + 10); 
        document.cookie = "lat=" + lonlat.lat + "; expires=" + expiry.toGMTString();
        document.cookie = "lon=" + lonlat.lon + "; expires=" + expiry.toGMTString();
        document.cookie = "zoom=" + zoom + "; expires=" + expiry.toGMTString();
        //document.cookie = "layers=" + layers + "; expires=" + expiry.toGMTString();
    }
    function setup() {
        $('body').addClass('dynamic');
        window.onbeforeunload = function() {
            for( var i = 0, l = changeables.length; i < l; ++i ) {
                if( typeof(changeables[i].changed) == 'function' && changeables[i].changed() ) {
                    return "You have unsaved data, only click OK if you are happy to lose these changes.";
                }
            }
        }
        authenticity_token = $('#token_form input').attr('value');
        var message = $('#message');
        if( message.find('h3').length ) {
            var visible = true;
            setTimeout( function() {
                if( visible ) {
                    message.hide();
                    visible = false;
                }
            }, 5000 );
            message.find('a').click(function() {
                if( visible ) {
                    message.hide();
                    visible = false;
                }
            });
        }
    }
    var errors = [];
    var error_timeout;
    function reportError(message) {
        errors.push(message);
        if( error_timeout )
            clearTimeout(error_timeout);
        error_timeout = setTimeout(displayErrors, 100);
    }

    function displayErrors() {
        if( errors.length == 1 ) {
            alert( errors[0] );
        } else {
            alert( "The following errors were found:\n\t"+errors.join("\n\t") );
        }
        errors = [];
    }

    return {
        getMapCenter: getMapCenter,
        getMapExtent: getMapExtent,
        getPageParams: getPageParams,
        reportError: reportError,
        addChangeable: addChangeable,
        removeChangeable: removeChangeable,
        getAuthenticityToken: getAuthenticityToken,
        getStartLocation: getStartLocation,
        getURLBase: getURLBase,
        setupMapEventHandlers: setupMapEventHandlers,
        setup: setup,
        1:1
    };
})();
    /*
    function updatePhotoStatus() {
        if( $(this).find('input').is(':checked') ) {
            $(this).addClass('selected');
        } else {
            $(this).removeClass('selected');
        }
    }
    this.area.addClass('selectable');
    this.area.find('li input').
    $('.photo_list.selectable li input').css('display','none');
    $('.photo_list.selectable li').each(updatePhotoStatus).click(function() {
        if( ajax_activity )
            return;
        var input = $(this).find('input').get(0);
        input.checked = !input.checked;
        updatePhotoStatus.call(this);
    });
    */


    /*
    $('#moderation_photos').selectable({
        'filter': 'li',
        'selected': function( e, obj ) {
            console.log( 'selected', this, arguments );
            var input = $(obj.selected).find('input').get(0);
            input.checked = true;
            updatePhotoStatus.call(obj.selected);
        },
        'start': function() { setAll(false); },
        'unselecting': function(e, obj) {
            console.log( 'unselecting', this, arguments );
            var input = $(obj.unselecting).find('input').get(0);
            input.checked = false;
            updatePhotoStatus.call(obj.unselecting);
        }
    });
    */

