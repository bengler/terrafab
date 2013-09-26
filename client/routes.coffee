Pather = require('pather')

path = new Pather()

path.on '/', ->
  require("./index_page.coffee")

path.on '/preview', ->
  require("./preview_page.coffee")

path.on '/cart', ->
  require("./cart_page.coffee")
