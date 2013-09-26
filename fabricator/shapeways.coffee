OAuth = require('oauth')
fs = require('fs');

API_HOST = "http://api.shapeways.com"

class ShapewaysClient
  constructor: (@consumerKey, @consumerSecret, @callbackURL) ->
    getRequestTokenUrl = API_HOST+"/oauth1/request_token/v1"
    getAccessTokenUrl = API_HOST+"/oauth1/access_token/v1"
    @oa = new OAuth.OAuth(
      getRequestTokenUrl,
      getAccessTokenUrl,
      @consumerKey,
      @consumerSecret,
      "1.0",
      @callbackURL,
      "HMAC-SHA1",
    )

  login: (callback) ->
    @oa.getOAuthRequestToken (error, oauth_token, oauth_token_secret, results) ->
      if error
        console.log 'error :' + JSON.stringify error
      url = results.authentication_url

      callback error, { oauth_token, oauth_token_secret, url }

  handleCallback:  (oauth_token, oauth_token_secret, oauth_verifier, callback) ->
    # Grab Access Token
    @oa.getOAuthAccessToken(
      oauth_token,
      oauth_token_secret,
      oauth_verifier,
      (error, oauth_access_token, oauth_access_token_secret, response) ->
        if error
          console.log 'error :' + JSON.stringify error
        if response is undefined
          console.log 'error: ' + response
        callback { oauth_access_token, oauth_access_token_secret }
    )

  getMaterials: (oauth_access_token, oauth_access_token_secret, callback) ->
    @oa.get(
      API_HOST+"/materials/v1",
      oauth_access_token,
      oauth_access_token_secret,
      (error, data, response) ->
        if error
          callback error, null
        if response is undefined
          callback ('error: ' + response), null
        callback null, JSON.parse(data)
    )

  getPrice: (options, oauth_access_token, oauth_access_token_secret, callback) ->
    @oa.post(
      API_HOST+"/price/v1",
      oauth_access_token,
      oauth_access_token_secret,
      JSON.stringify(options),
      (error, data, response) ->
        if error
          callback error, null
        else
          callback null, JSON.parse(data)
    )

  getModel: (modelId, oauth_access_token, oauth_access_token_secret, callback) ->
    @oa.get(
      API_HOST+"/models/"+modelId+"/v1",
      oauth_access_token,
      oauth_access_token_secret,
      (error, data, response) ->
        if error
          callback error, null
        else
          callback null, JSON.parse(data)
    )

  postModel: (params, oauth_access_token, oauth_access_token_secret, callback) ->
    # TODO: check if file already is posted to Shapeways through the API.
    fileName = ""+params.file
    model_upload = fs.readFile params.file, (err, fileData) =>
      fileData = encodeURIComponent fileData.toString('base64')
      params.file = fileData
      params.fileName = fileName
      @oa.post(
        API_HOST+"/models/v1",
        oauth_access_token,
        oauth_access_token_secret,
        JSON.stringify(params),
        (error, data, response) ->
          console.log error, data, response
          if error
            callback error, null
          else
            callback null, JSON.parse(data)
      )

  updateModel: (modelId, params, oauth_access_token, oauth_access_token_secret, callback) ->
    put = (params) =>
      @oa.put(
        API_HOST+"/models/"+modelId+"/info/v1",
        oauth_access_token,
        oauth_access_token_secret,
        JSON.stringify(params),
        (error, data, response) ->
          console.log error, data, response
          if error
            callback error, null
          else
            callback null, JSON.parse(data)
      )
    if params.file
      fileName = ""+params.file
      model_upload = fs.readFile params.file, (err, fileData) =>
        fileData = encodeURIComponent fileData.toString('base64')
        params.file = fileData
        params.fileName = fileName
        post(params)
    else
      put(params)

  addToCart: (modelId, materialId, quantity, oauth_access_token, oauth_access_token_secret, callback) ->
    params = {
      "modelId": modelId,
      "materialId": materialId,
      "quantity": quantity
    }
    @oa.post(
      API_HOST+"/orders/cart/v1",
      oauth_access_token,
      oauth_access_token_secret,
      JSON.stringify(params),
      (error, data, response) ->
        if error
          callback error, null
        else
          callback null, JSON.parse(data)
    )

module.exports = ShapewaysClient
