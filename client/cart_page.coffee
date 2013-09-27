window.$ = require("jquery")

waitInterval = null
uploadInterval = null
cart = null
cartPosted = false
progressCount = 0;
isShipped = false;

parseBoxParams = ->
  return /(?:box\=)([0-9\.\,]+)/.exec(window.location.search)[1].split(',')

searchToObject = ->
  pairs = window.location.search.substring(1).split("&")
  obj = {}
  for item in pairs
    unless item == ""
      pair = item.split("=")
      obj[decodeURIComponent(pair[0])] = decodeURIComponent(pair[1])
  obj

getCartData = ->
  modelId = searchToObject().modelId
  unless cart and cart.ready
    if modelId
      url = "/cartdata?modelId="+searchToObject().modelId
      $.get(url).fail((err, result) =>
        if err.status == 403 or err.status == 401
          return window.location = '/login?redirect_url='+encodeURIComponent(
            '/cart?modelId=' + modelId
          )
      ).then((cart) =>
        cart = JSON.parse(cart)
        if cart.ready and !cartPosted
          cartPosted = true
          $.post('/addtocart', {modelId: searchToObject().modelId, materialId: cart.materialId}).then( (result) =>
            clearInterval(waitInterval)
            window.location = JSON.parse(result).cartURL
          )
        else
          progressCount = progressCount+2 if progressCount < 99
          $(".progressTxt").html("Waiting for Shapeways...")
          $(".infoText").html("Shapeways is preparing the model for printing.<br/>You will be redirected to your Shapeways cart when ready.")
          $(".progress-bar").show()
          $(".progress-bar span").css("width", progressCount+"%")
      )
    else
      $(".infoText").html("Upload the model to Shapeways for printing and shipment.")
      $("a.buyButton").show()
      $("a.buyButton").on('click', =>
        unless isShipped
          clearInterval(waitInterval)
          $.post('/ship', {box: searchToObject().box}).then( (result) =>
            clearInterval(waitInterval)
            data = JSON.parse(result);
            return window.location = data.cartURL
          )
          $(".progressTxt").html("Uploading...")
          $(".infoText").html("Uploading the model to Shapeways, hang on.")
          progressCount = 1
          $(".progress-bar span").css("width", progressCount+"%")
          $(".progress-bar").show()
          $("a.buyButton").hide()
          uploadInterval = setInterval(
            =>
              progressCount = progressCount+2 if progressCount < 99
              $(".progress-bar span").css("width", progressCount+"%")
            , 1000)
          isShipped = true
        false
      )

$ ->
  if window.location.href.match("/cart")
    unless searchToObject().dev
      $("#tileSpinner").hide();
      $("#modelSpinner").hide();
      $(".progress-bar").hide()
      waitInterval = setInterval(getCartData, 2000)
      getCartData()
      $("a.buyButton").show() if(!searchToObject().modelId)
    else
      $("#infoTxt").show().html("I am info text")
      $("a.buyButton").show()
      $(".progressTxt").html("I am progress")
      $("a.buyButton").html("I am button")
