var NW = 0, NE = 1, SE = 2, SW = 3

var L = require("leaflet")

L.RectangleEditor = L.Polygon.extend ({
  options: {
    draggable: true,
    color: '#333',
    weight: 1,
    fillColor: '#ffb400',
    fillOpacity: 0.2
  },

  initialize: function(bounds, options) {
    this._latLngs = this.translateLatLngs(bounds);
    L.Polygon.prototype.initialize.call(this, this._latLngs, options);
  },
  _reset: function() {
    this._resizeMarkers = this.createResizeMarkers();

    var bounds = this.getBounds()
    this._resizeMarkers.sw.setLatLng(bounds.getSouthWest());
    this._resizeMarkers.ne.setLatLng(bounds.getNorthEast());
    this._resizeMarkers.se.setLatLng(bounds.getSouthEast());
    this._resizeMarkers.nw.setLatLng(bounds.getNorthWest());

    this._moveMarker = this.createMoveMarker(this.getBounds().getCenter());

    var allLayers = Object.keys(this._resizeMarkers).map(function(k) { return this._resizeMarkers[k] }, this).concat([this._moveMarker]);
    this._markerGroup = new L.LayerGroup(allLayers);
  },
  translateLatLngs: function(bounds) {
    bounds = L.latLngBounds(bounds)
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
  onAdd: function (map) {
    this._map = map;
    this._reset();

    this._moveMarker.on('drag', this._onMoveMarkerDrag, this);

    map.addLayer(this._markerGroup);

    // add a viewreset event listener for updating layer's position, do the latter
    map.on('viewreset', this._reset, this);

    L.Polygon.prototype.onAdd.call(this, map);
    this.setBounds(this.getBounds());
  },
  getBounds: function() {
    return new L.LatLngBounds(this._latLngs[SW], this._latLngs[NE])
  },
  setBounds: function (bounds) {
    this.setLatLngs(this.translateLatLngs(bounds));
  },
  setLatLngs: function (latLngs) {
    this._latLngs = latLngs;
    this._layoutMoveMarker();
    this._layoutResizeMarkers();
    L.Polygon.prototype.setLatLngs.call(this, latLngs)
  },
  getCenter: function() {
    return this.getBounds().getCenter();
  },
  _layoutMoveMarker: function() {
    var nwLatLng = this.getNorthWest();
    var seLatLng = this.getSouthEast();

    var nwPoint = this._map.project(nwLatLng);
    var sePoint = this._map.project(seLatLng);

    var h = Math.abs(nwPoint.y - sePoint.y);
    var w = Math.abs(nwPoint.x - sePoint.x);
    var centerPoint = this._map.project(this.getCenter());

    nwPoint.y = centerPoint.y+(h/2);
    nwPoint.x = centerPoint.x+(w/2);

    sePoint.y = centerPoint.y-(h/2);
    sePoint.x = centerPoint.x-(w/2);

    this._moveMarker.setLatLng(this.getCenter());
    this._moveMarker._icon.style.marginTop=(h/-2)+'px';
    this._moveMarker._icon.style.marginLeft=(w/-2)+'px';
    this._moveMarker._icon.style.height=(h)+'px';
    this._moveMarker._icon.style.width=(w)+'px';
  },
  _layoutResizeMarkers: function() {
    this._resizeMarkers.sw.setLatLng(this.getSouthWest());
    this._resizeMarkers.ne.setLatLng(this.getNorthEast());
    this._resizeMarkers.se.setLatLng(this.getSouthEast());
    this._resizeMarkers.nw.setLatLng(this.getNorthWest());
  },
  onRemove: function (map) {
    map.removeLayer(this._markerGroup);
    L.Path.prototype.onRemove.call(this, map);
  },
  createResizeMarkers: function () {
    var markers = {};
    markers.sw = this.createResizeMarker('sw');
    markers.ne = this.createResizeMarker('ne');
    markers.se = this.createResizeMarker('se');
    markers.nw = this.createResizeMarker('nw');
    return markers;
  },
  createMoveMarker: function() {
    var icon = new L.DivIcon({
      iconSize: [0, 0],
      iconAnchor: [0, 0],
      className: 'leaflet-div-icon leaflet-editing-icon moveable',
      cursor: 'move'
    });
    return new L.Marker(this.getBounds().getCenter(), {
      draggable: true,
      icon: icon
    });
  },
  createResizeMarker: function (cornerClass) {
    var markerIcon = new L.DivIcon({
      iconSize: new L.Point(12, 12),
      className: 'leaflet-div-icon leaflet-editing-icon corner-'+cornerClass
    });
    var marker = new L.Marker(null, {
      draggable: true,
      icon: markerIcon
    });
    marker.on('drag', this._onResizeMarkerDrag, this);
    return marker;
  },
  getNorthWest: function() {
    return this._latLngs[NW];
  },
  getNorthEast: function() {
    return this._latLngs[NE];
  },
  getSouthEast: function() {
    return this._latLngs[SE];
  },
  getSouthWest: function() {
    return this._latLngs[SW];
  },
  getLatLngs: function() {
    return this._latLngs
  },
  _onResizeMarkerDrag: function (e) {
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
  project: function(rectangle) {
    var bounds = new L.LatLngBounds(rectangle);
    this.setNorthWestAndSouthEast(bounds.getNorthWest(), bounds.getSouthEast())
    this.redraw();
  },
  getCenterLatLng: function() {
    var ne = this.getNorthEast()
    var nw = this.getNorthWest()
    var sw = this.getSouthWest()
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

  setCenterLatLng: function(latLng) {
    var nePoint = this._map.project(this._resizeMarkers.ne.getLatLng())
    var swPoint = this._map.project(this._resizeMarkers.sw.getLatLng())

    var centerPoint = this._map.project(latLng);

    var h = Math.abs(nePoint.y - swPoint.y);
    var w = Math.abs(swPoint.x - nePoint.x);

    nePoint.y = centerPoint.y+(h/2);
    nePoint.x = centerPoint.x+(w/2);

    swPoint.y = centerPoint.y-(h/2);
    swPoint.x = centerPoint.x-(w/2);

    this.setBounds(new L.LatLngBounds(this._map.unproject(swPoint), this._map.unproject(nePoint)))

  },
  _onMoveMarkerDrag: function (e) {
    this.setCenterLatLng(e.target.getLatLng())
  }
});
