L = require("leaflet")

RE = /(?:box\=)([0-9\.\-\,\|\d]+)/

matches = (str)->
  RE.test(str)

parseLocation = (str)->
  match = str.match(RE)
  match && match[1]

fromUrl = (location)->
  decode(parseLocation(String(location)))

decode = (boxparam)->
  [box, zoom] = boxparam.split("|")
  points = box.split(",")
  {
    zoom: zoom
    sw: L.point(points.slice(0,2))
    ne: L.point(points.slice(2))
  }

encode = ({sw, ne, zoom})->
  "#{[sw.x, sw.y, ne.x, ne.y].join(',')}|#{zoom}"

module.exports = {matches, fromUrl, decode, encode} 