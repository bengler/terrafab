var NW = 0, NE = 1, SE = 2, SW = 3

var L = require("leaflet")
L.RectangleEditor = L.Polygon.extend ({
  options: {
    draggable: true,
    color: '#333',
    weight: 1,
    fillColor: '#ffb400',
    fillOpacity: 0.2,
  },

  initialize: function(bounds, options) {
    this._latLngs = this.translateLatLngs(bounds);
    L.Polygon.prototype.initialize.call(this, this._latLngs, options);
  },

  onAdd: function (map) {
    this._latLngs = this.translateLatLngs(this._latLngs);

    L.Polygon.prototype.onAdd.call(this, map);

    this._resizeMarkers = this.createResizeMarkers();
    this._moveMarker = this.createMoveMarker(this.getCenter());
    this._moveMarker.on('drag', this._onMoveMarkerDrag, this);
    var allLayers = Object.keys(this._resizeMarkers).map(function(k) { return this._resizeMarkers[k]}, this).concat([this._moveMarker]);
    var markerGroup = new L.LayerGroup(allLayers);

    var bounds = this.getBounds()
    this.setNorthWestAndSouthEast(bounds.getNorthWest(), bounds.getSouthEast())
    map.addLayer(markerGroup);
    this._layoutResizeMarkers(this._latLngs);
    this._layoutMoveMarker(this._latLngs);
  },

  createResizeMarkers: function () {
    var markers = {};
    markers.sw = this.createMarker('sw', this._latLngs[SW]);
    markers.ne = this.createMarker('ne', this._latLngs[NE]);
    markers.se = this.createMarker('se', this._latLngs[SE]);
    markers.nw = this.createMarker('nw', this._latLngs[NW]);
    return markers;
  },
  createMarker: function (cornerClass, latLng) {
    var markerIcon = new L.DivIcon({
      iconSize: new L.Point(12, 12),
      className: 'leaflet-div-icon leaflet-editing-icon corner-'+cornerClass
    });
    var marker = new L.Marker(latLng, {
      draggable: true,
      icon: markerIcon
    });
    marker.on('drag', this._onMarkerDrag, this);
    return marker;
  },
  onRemove: function (map) {
    this.tearDown();
    L.Path.prototype.onRemove.call(this, map);
  },
  createMoveMarker: function(latlng) {
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
  _onMarkerDrag: function (e) {
    var marker = e.target;
    if (marker == this._resizeMarkers.nw) {
      this.setNorthWest(marker.getLatLng())
    }
    else if (marker == this._resizeMarkers.se) {
      this.setSouthEast(marker.getLatLng())
    }
    else if (marker == this._resizeMarkers.sw) {
      this.setSouthWest(marker.getLatLng())
    }
    else if (marker == this._resizeMarkers.ne) {
      this.setNorthEast(marker.getLatLng())
    }
  },
  translateLatLngs: function(bounds) {
    bounds = L.latLngBounds(bounds);
    var nwLatLng = bounds.getNorthWest();
    var seLatLng = bounds.getSouthEast();

    var swLatLng;
    var neLatLng;
    if (this._map) {
      var nwPoint = this._map.project(nwLatLng);
      var sePoint = this._map.project(seLatLng);

      var nePoint = new L.Point(sePoint.x, nwPoint.y);
      var swPoint = new L.Point(nwPoint.x, sePoint.y);

      swLatLng = this._map.unproject(swPoint);
      neLatLng = this._map.unproject(nePoint);
    }
    else {
      swLatLng = bounds.getSouthWest()
      neLatLng = bounds.getNorthEast()
    }
    return [nwLatLng, neLatLng, seLatLng, swLatLng]
  },
  setLatLngs: function(latLngs) {
    this._layoutResizeMarkers(latLngs);
    this._layoutMoveMarker(latLngs);
    L.Polygon.prototype.setLatLngs.call(this, latLngs);
  },
  _layoutResizeMarkers: function(latLngs) {
    this._resizeMarkers.sw.setLatLng(latLngs[SW]);
    this._resizeMarkers.ne.setLatLng(latLngs[NE]);
    this._resizeMarkers.se.setLatLng(latLngs[SE]);
    this._resizeMarkers.nw.setLatLng(latLngs[NW]);
    this.redraw()
  },
  _layoutMoveMarker: function(latLngs) {
    this._moveMarker.setLatLng(new L.LatLngBounds(latLngs).getCenter());
  },
  setNorthWestAndSouthEast: function(nwLatLng, seLatLng) {
    var nwPoint = this._map.project(nwLatLng);
    var sePoint = this._map.project(seLatLng);

    var nePoint = new L.Point(sePoint.x, nwPoint.y);
    var swPoint = new L.Point(nwPoint.x, sePoint.y);

    var swLatLng = this._map.unproject(swPoint);
    var neLatLng = this._map.unproject(nePoint);

    this.setLatLngs([nwLatLng, neLatLng, seLatLng, swLatLng])
  },

  setNorthWest: function(latLng) {
    this.setNorthWestAndSouthEast(latLng, this._latLngs[SE])
  },
  setSouthEast: function(latLng) {
    this.setNorthWestAndSouthEast(this._latLngs[NW], latLng)
  },
  setNorthEast: function(latLng) {
    this.setNorthEastAndSouthWest(latLng, this._latLngs[SW])
  },
  setSouthWest: function(latLng) {
    this.setNorthEastAndSouthWest(this._latLngs[NE], latLng)
  },
  setNorthEastAndSouthWest: function(neLatLng, swLatLng) {
    var nePoint = this._map.project(neLatLng);
    var swPoint = this._map.project(swLatLng);

    var nwPoint = new L.Point(swPoint.x, nePoint.y);
    var sePoint = new L.Point(nePoint.x, swPoint.y);

    var nwLatLng = this._map.unproject(nwPoint);
    var seLatLng = this._map.unproject(sePoint);

    this.setLatLngs([nwLatLng, neLatLng, seLatLng, swLatLng])
  },
  getCenter: function() {
    return new L.LatLngBounds(this._latLngs).getCenter();
  },
  setCenter: function(latLng) {
    var nePoint = this._map.project(this._latLngs[NE]);
    var swPoint = this._map.project(this._latLngs[SW]);

    var centerPoint = this._map.project(latLng);

    var h = Math.abs(nePoint.y - swPoint.y);
    var w = Math.abs(swPoint.x - nePoint.x);

    nePoint.y = centerPoint.y+(h/2);
    nePoint.x = centerPoint.x+(w/2);

    swPoint.y = centerPoint.y-(h/2);
    swPoint.x = centerPoint.x-(w/2);

    var swLatLng = this._map.unproject(swPoint);
    var neLatLng = this._map.unproject(nePoint);
    this.setNorthEastAndSouthWest(neLatLng, swLatLng)
  },
  _onMoveMarkerDrag: function (e) {
    this.setCenter(e.target.getLatLng());
    this.redraw();
  },

  tearDown: function() {
    this._map.removeLayer(this._resizeMarkers.sw);
    this._map.removeLayer(this._resizeMarkers.se);
    this._map.removeLayer(this._resizeMarkers.nw);
    this._map.removeLayer(this._resizeMarkers.ne);
    this._map.removeLayer(this._moveMarker);
  }

});
