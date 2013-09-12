var L = require("leaflet")

L.RectangleEditor = L.Rectangle.extend ({
  options: {
    draggable: true,
    color: '#fff',
    weight: 1,
    fillColor: '#333',
    fillOpacity: 0.4,
    constraints: {
      aspectRatio: 1
    }
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
    this._dragMarker.on('drag', this._onDragMarkerDrag, this);
    this._dragMarker.on('dragend', this._onDragEnd, this);
    var allLayers = Object.keys(this.markers).map(function(k) { return this.markers[k]}, this).concat([this._dragMarker]);
    var markerGroup = new L.LayerGroup(allLayers);
    map.addLayer(markerGroup);
    this.on('change', function(e) {
      this.resizeDragMarker();
    });
    this.resizeDragMarker();
  },

  resizeDragMarker: function(e) {
    setTimeout(function() {
      if(this._parts && this._parts[0]) {
        this._dragMarker.setIcon(new L.Icon({
            iconUrl: '/images/transparent.png',
            iconSize: [this._parts[0][2].x-this._parts[0][0].x,this._parts[0][2].x-this._parts[0][0].x],
            className: 'leaflet-div-icon leaflet-editing-icon moveable',
            cursor: 'move'
          })
        );
      }
    }.bind(this), 100);
  },

  createMarkers: function () {
    var myBounds = this.getBounds();
    var markers = {};
    markers.sw = this.createMarker(myBounds.getSouthWest(), 'sw');
    markers.se = this.createMarker(myBounds.getSouthEast(), 'se');
    markers.nw = this.createMarker(myBounds.getNorthWest(), 'nw');
    markers.ne = this.createMarker(myBounds.getNorthEast(), 'ne');
    this._opposites = {
      se: 'nw',
      nw: 'se',
      sw: 'ne',
      ne: 'sw'
    };
    return markers;
  },
  createDragMarker: function(latlng) {
    // [this._parts[2].x-this._parts[0].x, this._parts[2].y-this._parts[0].y]
    var icon = new L.Icon({
      iconUrl: '/images/glyphicons_186_move.png',
      iconSize: [100,100],
      className: 'leaflet-div-icon leaflet-editing-icon moveable',
      cursor: 'move'
    });
    return new L.Marker(latlng, {
      draggable: true,
      icon: icon
    });
  },
  createMarker: function (latlng, cornerClass) {
    var markerIcon = new L.DivIcon({
      iconSize: new L.Point(8, 8),
      className: 'leaflet-div-icon leaflet-editing-icon corner-'+cornerClass
    });
    var marker = new L.Marker(latlng, {
      draggable: true,
      icon: markerIcon
    });
    marker.on('drag', this._onMarkerDrag, this);
    marker.on('dragend', this._onMarkerMouseUp, this);
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
    this.fire('change', {bounds: this.getMarkerBounds()[0]})
  },
  _onMarkerDrag: function (e) {
    var marker = e.target;
    this.extendTo(marker);
    this.setBounds(this.getMarkerBounds());
    this.redraw();
  },
  _onMarkerMouseUp: function(e) {
    this.fire('mouseup', {bounds: this.getMarkerBounds()[0]});
  },
  _onDragEnd: function (e) {
    this.fire('dragend', {bounds: this.getMarkerBounds()[0]});
    this.fire('mouseup', {bounds: this.getMarkerBounds()[0]});
  },
  project: function(rectangle) {
    var theBounds = new L.LatLngBounds(rectangle);
    this.markers.sw.setLatLng(theBounds.getSouthWest());
    this.markers.se.setLatLng(theBounds.getSouthEast());
    this.markers.nw.setLatLng(theBounds.getNorthWest());
    this.markers.ne.setLatLng(theBounds.getNorthEast());
    this._dragMarker.setLatLng(theBounds.getCenter());
    this.setBounds(this.getMarkerBounds());
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
    this.fire('change', {bounds: this.getMarkerBounds()[0]})
  },
  _onDragMarkerDrag: function (e) {
    this.setCenterLatLng(e.target.getLatLng())
    this.redraw();
  },

  tearDown: function() {
    this._map.removeLayer(this.markers.sw);
    this._map.removeLayer(this.markers.se);
    this._map.removeLayer(this.markers.nw);
    this._map.removeLayer(this.markers.ne);
    this._map.removeLayer(this._dragMarker);
  }

});
