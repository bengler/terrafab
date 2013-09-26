var NW = 0, NE = 1, SE = 2, SW = 3

var L = require("leaflet");

L.RectangleEditor = L.Polygon.extend ({
  options: {
    color: '#333',
    weight: 1,
    fillColor: '#ffb400',
    fillOpacity: 0.2,
    constraints: {
      aspectRatio: 1
    },
    projection: L.CRS.EPSG3857.projection
  },

  initialize: function(bounds, options) {
    L.setOptions(this, options || {});
    this._latLngs = this.translateLatLngs(bounds);
    L.Polygon.prototype.initialize.call(this, this._latLngs, options);
  },

  onAdd: function (map) {

    L.Polygon.prototype.onAdd.call(this, map);

    this._resizeMarkers = this.createResizeMarkers();
    this._moveMarker = this.createMoveMarker(this.getCenter());

    this._moveMarker.on('drag', this._onMoveMarkerDrag, this);

    var allLayers = Object.keys(this._resizeMarkers).map(function(k) { return this._resizeMarkers[k]}, this).concat([this._moveMarker]);
    var markerGroup = new L.LayerGroup(allLayers);

    map.addLayer(markerGroup);
    map.on('zoomend', function() {
      this._layoutMoveMarker()
    }.bind(this))
    this._layoutMoveMarker()
  },

  createResizeMarkers: function () {
    var markers = {};
    markers.sw = this.createResizeMarker('sw', this._latLngs[SW]);
    markers.ne = this.createResizeMarker('ne', this._latLngs[NE]);
    markers.se = this.createResizeMarker('se', this._latLngs[SE]);
    markers.nw = this.createResizeMarker('nw', this._latLngs[NW]);
    return markers;
  },
  createResizeMarker: function (cornerClass, latLng) {
    var markerIcon = new L.DivIcon({
      iconSize: new L.Point(16, 16),
      className: 'leaflet-div-icon leaflet-editing-icon corner-'+cornerClass
    });
    var marker = new L.Marker(latLng, {
      draggable: true,
      icon: markerIcon
    });
    marker.on('drag', this._onResizeMarkerDrag, this);
    return marker;
  },
  onRemove: function (map) {
    this.tearDown();
    L.Path.prototype.onRemove.call(this, map);
  },
  createMoveMarker: function(latLng) {
    var icon = new L.DivIcon({
      iconSize: [100,100],
      className: 'leaflet-div-icon leaflet-editing-icon moveable',
      cursor: 'move'
    });
    return new L.Marker(latLng, {
      draggable: true,
      icon: icon
    });
  },
  _onResizeMarkerDrag: function (e) {
    var marker = e.target;
    if (marker == this._resizeMarkers.nw) {
      this.setNorthWest(this.constrainTo(marker.getLatLng(), this._latLngs[SE], this.options.constraints.aspectRatio))
    }
    else if (marker == this._resizeMarkers.se) {
      this.setSouthEast(this.constrainTo(marker.getLatLng(), this._latLngs[NW], this.options.constraints.aspectRatio))
    }
    else if (marker == this._resizeMarkers.sw) {
      this.setSouthWest(this.constrainTo(marker.getLatLng(), this._latLngs[NE], this.options.constraints.aspectRatio))
    }
    else if (marker == this._resizeMarkers.ne) {
      this.setNorthEast(this.constrainTo(marker.getLatLng(), this._latLngs[SW], this.options.constraints.aspectRatio))
    }
  },
  translateLatLngs: function(bounds) {
    bounds = L.latLngBounds(bounds);
    var neLatLng = bounds.getNorthEast();
    var swLatLng = bounds.getSouthWest();

    var nePoint = this.project(neLatLng);
    var swPoint = this.project(swLatLng);

    var nwPoint = new L.Point(swPoint.x, nePoint.y);
    var sePoint = new L.Point(nePoint.x, swPoint.y);

    var nwLatLng = this.unproject(nwPoint);
    var seLatLng = this.unproject(sePoint);
    return [nwLatLng, neLatLng, seLatLng, swLatLng]
  },
  setLatLngs: function(latLngs) {
    this._latLngs = latLngs;
    L.Polygon.prototype.setLatLngs.call(this, latLngs);
    this._layoutResizeMarkers();
    this._layoutMoveMarker();
    this.fire('change')
  },
  _layoutResizeMarkers: function() {
    this._resizeMarkers.sw.setLatLng(this._latLngs[SW]);
    this._resizeMarkers.ne.setLatLng(this._latLngs[NE]);
    this._resizeMarkers.se.setLatLng(this._latLngs[SE]);
    this._resizeMarkers.nw.setLatLng(this._latLngs[NW]);
  },
  _layoutMoveMarker: function() {
    var nwPoint = this._map.project(this._latLngs[NW]);
    var sePoint = this._map.project(this._latLngs[SE]);

    var center = this.getCenter()
    var h = Math.abs(nwPoint.y - sePoint.y);
    var w = Math.abs(nwPoint.x - sePoint.x);

    this._moveMarker.setLatLng(center);
    if (this._moveMarker._icon) {
      this._moveMarker._icon.style.marginTop=(h/-2)+'px';
      this._moveMarker._icon.style.marginLeft=(w/-2)+'px';
      this._moveMarker._icon.style.height=(h)+'px';
      this._moveMarker._icon.style.width=(w)+'px';      
    } 
  },
  setNorthWestAndSouthEast: function(nwLatLng, seLatLng) {
    var nwPoint = this.project(nwLatLng);
    var sePoint = this.project(seLatLng);

    var nePoint = new L.Point(sePoint.x, nwPoint.y);
    var swPoint = new L.Point(nwPoint.x, sePoint.y);

    var swLatLng = this.unproject(swPoint);
    var neLatLng = this.unproject(nePoint);

    this.setLatLngs([nwLatLng, neLatLng, seLatLng, swLatLng])
  },
  project: function(latLng) {
    return this.options.projection.project(latLng)
  },
  unproject: function(point) {
    return this.options.projection.unproject(point)
  },
  constrainTo: function(latLng, oppositeLatLng, aspectRatio) {
    var point = this.project(latLng);
    var oppositePoint = this.project(oppositeLatLng);
    
    var w = Math.abs(oppositePoint.x - point.x);
    var diffX = w * aspectRatio;
    var constrainedPoint;
    if (oppositePoint.y < point.y) {
      constrainedPoint = new L.Point(point.x, oppositePoint.y + diffX);
    } else {
      constrainedPoint =new L.Point(point.x, oppositePoint.y - diffX);
    }
    return this.unproject(constrainedPoint);
  },
  getSouthWest: function() {
    return this._latLngs[SW];
  },
  getNorthWest: function() {
    return this._latLngs[NW];
  },
  getSouthEast: function() {
    return this._latLngs[SE];
  },
  getNorthEast: function() {
    return this._latLngs[NE];
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
    var nePoint = this.project(neLatLng);
    var swPoint = this.project(swLatLng);

    var nwPoint = new L.Point(swPoint.x, nePoint.y);
    var sePoint = new L.Point(nePoint.x, swPoint.y);

    var nwLatLng = this.unproject(nwPoint);
    var seLatLng = this.unproject(sePoint);

    this.setLatLngs([nwLatLng, neLatLng, seLatLng, swLatLng])
  },
  getCenter: function() {
    return new L.LatLngBounds(this._latLngs).getCenter();
  },
  setCenter: function(latLng) {
    var nePoint = this.project(this._latLngs[NE]);
    var swPoint = this.project(this._latLngs[SW]);

    var centerPoint = this.project(latLng);

    var h = Math.abs(nePoint.y - swPoint.y);
    var w = Math.abs(swPoint.x - nePoint.x);

    nePoint.y = centerPoint.y+(h/2);
    nePoint.x = centerPoint.x+(w/2);

    swPoint.y = centerPoint.y-(h/2);
    swPoint.x = centerPoint.x-(w/2);

    var swLatLng = this.unproject(swPoint);
    var neLatLng = this.unproject(nePoint);
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
