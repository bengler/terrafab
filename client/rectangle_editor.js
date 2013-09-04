var L = require("leaflet")

L.RectangleEditor = L.Rectangle.extend ({
  options: {
    icon: new L.DivIcon({
      iconSize: new L.Point(8, 8),
      className: 'leaflet-div-icon leaflet-editing-icon'
    })
  },

  onAdd: function (map) {
    L.Path.prototype.onAdd.call(this, map);
    this.setup(map);
  },

  onRemove: function (map) {
    this.tearDown();
    L.Path.prototype.onRemove.call(this, map);
  },

  setup: function(map) {
    this.markers = this.createMarkers();
    var markerGroup = new L.LayerGroup(Object.keys(this.markers).map(function(k) { return this.markers[k] }, this));
    map.addLayer(markerGroup)
  },

  createMarkers: function () {
    var myBounds = this.getBounds();
    var markers = {};
    markers.sw = this.createMarker(myBounds.getSouthWest());
    markers.se = this.createMarker(myBounds.getSouthEast());
    markers.nw = this.createMarker(myBounds.getNorthWest());
    markers.ne = this.createMarker(myBounds.getNorthEast());
    return markers;
  },

  createMarker: function (latlng) {
    var marker = new L.Marker(latlng, {
      draggable: true,
      icon: this.options.icon
    });
    marker.on('drag', this._onMarkerDrag, this);
    return marker;
  },
  getMarkerBounds: function() {
    return [new L.LatLngBounds(this.markers.sw.getLatLng(), this.markers.ne.getLatLng())];
  },
  extendTo: function(marker) {
    // Ok, this was certainly quick and dirty
    // Todo: constrain to aspect ratio 
    var markerLatLng = marker.getLatLng()
    var swLatLng = this.markers.sw.getLatLng()
    var seLatLng = this.markers.se.getLatLng()
    var neLatLng = this.markers.ne.getLatLng()
    var nwLatLng = this.markers.nw.getLatLng()
    if (marker == this.markers.sw) {
      this.markers.nw.setLatLng([nwLatLng.lat, markerLatLng.lng]) 
      this.markers.se.setLatLng([markerLatLng.lat, seLatLng.lng]) 
    }
    else if (marker == this.markers.nw) {
      this.markers.ne.setLatLng([markerLatLng.lat, neLatLng.lng])
      this.markers.sw.setLatLng([swLatLng.lat, markerLatLng.lng])
    }
    else if (marker == this.markers.ne) {
      this.markers.se.setLatLng([seLatLng.lat, markerLatLng.lng])
      this.markers.nw.setLatLng([markerLatLng.lat, nwLatLng.lng])
    }
    else if (marker == this.markers.se) {
      this.markers.ne.setLatLng([neLatLng.lat, markerLatLng.lng])
      this.markers.sw.setLatLng([markerLatLng.lat, swLatLng.lng])
    }
  },
  _onMarkerDrag: function (e) {
    var marker = e.target;    
    this.extendTo(marker)
    this.setBounds(this.getMarkerBounds())
    this.redraw();
  }

});
