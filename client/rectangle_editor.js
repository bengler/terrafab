
var L = require("leaflet")
L.RectangleEditor = L.Rectangle.extend ({
  options: {
    draggable: true,
    color: '#333',
    weight: 1,
    fillColor: '#ffb400',
    fillOpacity: 0.2,
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

    var bounds = this.getBounds()
    this.setNorthWestAndSouthEast(bounds.getNorthWest(), bounds.getSouthEast())
    map.addLayer(markerGroup);
  },

  createMarkers: function () {
    var markers = {};
    markers.sw = this.createMarker('sw');
    markers.ne = this.createMarker('ne');
    markers.se = this.createMarker('se');
    markers.nw = this.createMarker('nw');
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
  createMarker: function (cornerClass) {
    var markerIcon = new L.DivIcon({
      iconSize: new L.Point(12, 12),
      className: 'leaflet-div-icon leaflet-editing-icon corner-'+cornerClass
    });
    var marker = new L.Marker(null, {
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
  _onMarkerDrag: function (e) {
    var marker = e.target;
    if (marker == this.markers.nw) {
      this.setNorthWest(marker.getLatLng())
    }
    else if (marker == this.markers.se) {
      this.setSouthEast(marker.getLatLng())
    }
    else if (marker == this.markers.sw) {
      this.setSouthWest(marker.getLatLng())
    }
    else if (marker == this.markers.ne) {
      this.setNorthEast(marker.getLatLng())
    }
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
  getCenterLatLng: function() {
    var ne = this.markers.ne.getLatLng()
    var nw = this.markers.nw.getLatLng()
    var sw = this.markers.sw.getLatLng()
    var distLng = ((ne.lng - nw.lng)/2);
    var distLat = ((ne.lat - sw.lat)/ 2);
    var latLng = new L.LatLng((ne.lat - distLat),(sw.lng-distLng))
    return this.crs ? [latLng,this.crs.project(latLng)] : [latLang]
  },
  setNorthWestAndSouthEast: function(nwLatLng, seLatLng) {
    var nwPoint = this._map.project(nwLatLng);
    var sePoint = this._map.project(seLatLng);

    var nePoint = new L.Point(sePoint.x, nwPoint.y);
    var swPoint = new L.Point(nwPoint.x, sePoint.y);

    var swLatLng = this._map.unproject(swPoint);
    var neLatLng = this._map.unproject(nePoint);

    this.markers.sw.setLatLng(swLatLng);
    this.markers.ne.setLatLng(neLatLng);
    this.markers.se.setLatLng(seLatLng);
    this.markers.nw.setLatLng(nwLatLng);

    this.setLatLngs([nwLatLng, neLatLng, seLatLng, swLatLng])
  },
  setNorthWest: function(latLng) {
    this.setNorthWestAndSouthEast(latLng, this.markers.se.getLatLng())
  },
  setSouthEast: function(latLng) {
    this.setNorthWestAndSouthEast(this.markers.nw.getLatLng(), latLng)
  },
  setNorthEast: function(latLng) {
    this.setNorthEastAndSouthWest(latLng, this.markers.sw.getLatLng())
  },
  setSouthWest: function(latLng) {
    this.setNorthEastAndSouthWest(this.markers.ne.getLatLng(), latLng)
  },
  setNorthEastAndSouthWest: function(neLatLng, swLatLng) {
    var nePoint = this._map.project(neLatLng);
    var swPoint = this._map.project(swLatLng);

    var nwPoint = new L.Point(swPoint.x, nePoint.y);
    var sePoint = new L.Point(nePoint.x, swPoint.y);

    var nwLatLng = this._map.unproject(nwPoint);
    var seLatLng = this._map.unproject(sePoint);

    this.markers.sw.setLatLng(swLatLng);
    this.markers.ne.setLatLng(neLatLng);
    this.markers.se.setLatLng(seLatLng);
    this.markers.nw.setLatLng(nwLatLng);

    this.setLatLngs([nwLatLng, neLatLng, seLatLng, swLatLng])
  },
  setCenterLatLng: function(latLng) {
    var nwPoint = this._map.project(this.markers.nw.getLatLng())
    var sePoint = this._map.project(this.markers.se.getLatLng())

    var centerPoint = this._map.project(latLng);

    var h = nwPoint.y - sePoint.y;
    var w = nwPoint.x - sePoint.x;

    nwPoint.y = centerPoint.y+(h/2);
    nwPoint.x = centerPoint.x+(w/2);
    
    sePoint.y = centerPoint.y-(h/2);
    sePoint.x = centerPoint.x-(w/2);

    this.setNorthWestAndSouthEast(this._map.unproject(nwPoint), this._map.unproject(sePoint))

    this._dragMarker.setLatLng(latLng);

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
