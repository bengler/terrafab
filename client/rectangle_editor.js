var L = require("leaflet")

L.RectangleEditor = L.Rectangle.extend ({
  options: {
    draggable: true,
    constraints: {
      aspectRatio: 0.5
    },
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
    this._dragMarker = this.createDragMarker(this.getBounds().getCenter());
    this._dragMarker.on('drag', this._onDragMarkerDrag, this)
    var allLayers = Object.keys(this.markers).map(function(k) { return this.markers[k]}, this).concat([this._dragMarker]);
    var markerGroup = new L.LayerGroup(allLayers);
    map.addLayer(markerGroup)
  },

  createMarkers: function () {
    var myBounds = this.getBounds();
    var markers = {};
    markers.sw = this.createMarker(myBounds.getSouthWest());
    markers.se = this.createMarker(myBounds.getSouthEast());
    markers.nw = this.createMarker(myBounds.getNorthWest());
    markers.ne = this.createMarker(myBounds.getNorthEast());
    this._opposites = {
      se: 'nw',
      nw: 'se',
      sw: 'ne',
      ne: 'sw'
    };
    return markers;
  },
  createDragMarker: function(latlng) {
    return new L.Marker(latlng, {
      draggable: true,
      icon: this.options.icon
    });
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
  getOppositeOf: function(marker) {
    for (var key in this.markers) if (this.markers.hasOwnProperty(key)) {
      if (marker == this.markers[key]) {
        return this.markers[this._opposites[key]];
      }
    }
  },
  extendTo: function(draggedMarker) {
    var markerLatLng = draggedMarker.getLatLng();
    var swLatLng = this.markers.sw.getLatLng();
    var seLatLng = this.markers.se.getLatLng();
    var neLatLng = this.markers.ne.getLatLng();
    var nwLatLng = this.markers.nw.getLatLng();

    var aspectRatio = this.options.constraints.aspectRatio;
    if (aspectRatio !== undefined) {
      var opposite = this.getOppositeOf(draggedMarker)

      var oppositePoint = this._map.project(opposite.getLatLng())
      var dragPoint = this._map.project(draggedMarker.getLatLng())

      var diffX = Math.abs(oppositePoint.x - dragPoint.x) * aspectRatio;

      if (oppositePoint.y < dragPoint.y) {
        dragPoint.y = oppositePoint.y + diffX;
      } else {
        dragPoint.y = oppositePoint.y - diffX;
      }
      markerLatLng = this._map.unproject(dragPoint);
      draggedMarker.setLatLng(markerLatLng)
    }
    if (draggedMarker == this.markers.sw) {
      this.markers.nw.setLatLng([nwLatLng.lat, markerLatLng.lng]) 
      this.markers.se.setLatLng([markerLatLng.lat, seLatLng.lng])
    }
    else if (draggedMarker == this.markers.nw) {
      this.markers.ne.setLatLng([markerLatLng.lat, neLatLng.lng])
      this.markers.sw.setLatLng([swLatLng.lat, markerLatLng.lng])
    }
    else if (draggedMarker == this.markers.ne) {
      this.markers.se.setLatLng([seLatLng.lat, markerLatLng.lng])
      this.markers.nw.setLatLng([markerLatLng.lat, nwLatLng.lng])
    }
    else if (draggedMarker == this.markers.se) {
      this.markers.ne.setLatLng([neLatLng.lat, markerLatLng.lng])
      this.markers.sw.setLatLng([markerLatLng.lat, swLatLng.lng])
    }
    this._dragMarker.setLatLng(this.getMarkerBounds()[0].getCenter())
  },
  _onMarkerDrag: function (e) {
    var marker = e.target;    
    this.extendTo(marker)
    this.setBounds(this.getMarkerBounds())
    this.redraw();
  },
  setCenterLatLng: function(latLng) {
    var ne = this.markers.ne.getLatLng()
    var nw = this.markers.nw.getLatLng()
    var sw = this.markers.sw.getLatLng()
    var distLng = ((ne.lng - nw.lng)/2);
    var distLat = ((ne.lat - sw.lat)/ 2);
    this.markers.ne.setLatLng([latLng.lat + distLat, latLng.lng + distLng]);
    this.markers.nw.setLatLng([latLng.lat + distLat, latLng.lng - distLng]);
    this.markers.se.setLatLng([latLng.lat - distLat, latLng.lng + distLng]);
    this.markers.sw.setLatLng([latLng.lat - distLat, latLng.lng - distLng]);
    this.setBounds(this.getMarkerBounds())
  },
  _onDragMarkerDrag: function (e) {
    this.setCenterLatLng(e.target.getLatLng())
    this.redraw();
  }

});
