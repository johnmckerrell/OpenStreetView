var epsg4326 = new OpenLayers.Projection("EPSG:4326");
var OSVMain = (function() {
    var map, markers, map_move_timeout;
    var photos = {};
    
    function mapChange() {
        if( map_move_timeout )
            clearTimeout(map_move_timeout);
        map_move_timeout = setTimeout(mapChangeTimeout, 500);
        updateLinks();
    }
    function updateLinks() {
        var center = OSV.getMapCenter(map);
        var zoom = map.getZoom();
        $('#permalink').attr('href',OSV.getURLBase()+'?lat='+center.lat+'&lon='+center.lon+'&zoom='+zoom);
        $('#kmllink').attr('href',getLocateLink('kml'));
    }
    function getLocateLink(format) {
        var extent = OSV.getMapExtent(map);
        var url = OSV.getURLBase()+'/api/photos/locate.'+format+'?bbox=';
        url += [ extent.left, extent.bottom, extent.right, extent.top].join(',');
        return url;
    }
    function mapChangeTimeout() {
        map_move_timeout = null;
        var url = getLocateLink('json');
        $.get( url, null, photosLoaded, 'json' );
    }
    function photosLoaded(json) {
        var new_photos = {};
        var size = new OpenLayers.Size(50, 50);
        var offset = new OpenLayers.Pixel(-25, -25);
        for( var i = 0, l = json.length; i < l; ++i ) {
            var p = new OSVPhoto(json[i]);
            if( photos[p.data.id] ) {
                new_photos[p.data.id] = photos[p.data.id];
                photos[p.data.id] = null;
            } else {
                var position = new OpenLayers.LonLat(p.data.lon,p.data.lat);
                var icon = new OpenLayers.Icon(p.url('square'), size, offset);

                p.feature  = new OpenLayers.Feature(markers, position.clone().transform(epsg4326, map.getProjectionObject()));
	        p.feature.closeBox = true;
            	p.feature.popupClass = OpenLayers.Class(OpenLayers.Popup.FramedCloud, {'autoSize': true});
		var popupContentHTML = "<img src="+p.url('medium')+'></img><p><a href="'+p.url('large')+'" target="_blank">Large size (in new tab)</a></p>';
		p.feature.data.popupContentHTML = popupContentHTML;
            	p.feature.data.overflow = "auto";
		p.feature.data.icon = icon;

                new_photos[p.data.id] = p;
		p.marker = p.feature.createMarker();
    		p.marker.id = p.data.id;
    		var markerClick = function (evt) {
	                if (this.popup == null) {
	                    this.popup = this.createPopup(true);
	                    map.addPopup(this.popup);
	                    this.popup.show();
	                } else {
	                    this.popup.toggle();
                }
                currentPopup = this.popup;
                OpenLayers.Event.stop(evt);
    		};
		p.marker.events.register("mousedown", p.feature, markerClick);
		p.marker.events.register("touchstart", p.feature, markerClick);
                markers.addMarker(p.marker);

                
            }
        }
        for( var k in photos ) {
            var p = photos[k];
            if( p && p.marker )
                markers.removeMarker(p.marker);
        }
        photos = new_photos;
    }
    function setup() {
        var vectors;
        var popup;

        map = new OpenLayers.Map($('#map').get(0), {
            controls: [
                new OpenLayers.Control.ArgParser(),
                new OpenLayers.Control.Attribution(),
                new OpenLayers.Control.LayerSwitcher(),
                new OpenLayers.Control.Navigation(),
                new OpenLayers.Control.PanZoomBar()
            ],
            units: "m",
            maxResolution: 156543.0339,
            numZoomLevels: 20,
            displayProjection: new OpenLayers.Projection("EPSG:4326")
        });

        var mapnik = new OpenLayers.Layer.OSM.Mapnik("Mapnik", {
            displayOutsideMaxExtent: true,
            wrapDateLine: true
        });
        map.addLayer(mapnik);

        var osmarender = new OpenLayers.Layer.OSM.Osmarender("Osmarender", {
            displayOutsideMaxExtent: true,
            wrapDateLine: true
        });
        map.addLayer(osmarender);

        var numZoomLevels = Math.max(mapnik.numZoomLevels, osmarender.numZoomLevels);

        var start = OSV.getStartLocation();
        var numzoom = map.getNumZoomLevels();
        if (start.zoom >= numzoom) start.zoom = numzoom - 1;
        map.setCenter(start.pos.clone().transform(epsg4326, map.getProjectionObject()), start.zoom);
        OSV.setupMapEventHandlers(map);
        map.events.register("moveend", map, mapChange);
        map.events.register("zoomend", map, mapChange);
        mapChange();



        markers = new OpenLayers.Layer.Markers("Markers", {
            displayInLayerSwitcher: false,
            numZoomLevels: numZoomLevels,
            maxExtent: new OpenLayers.Bounds(-20037508,-20037508,20037508,20037508),
            maxResolution: 156543,
            units: "m",
            projection: "EPSG:900913"
        });
        map.addLayer(markers);

    }
    return {
        setup: setup,
        1:1
    };
})();
$(function(){
    OSVMain.setup();
});
