OAuth = require('oauth')

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
    @oa.getOAuthAccessToken oauth_token, oauth_token_secret, oauth_verifier, (error, oauth_access_token, oauth_access_token_secret, response) ->
      if error
        console.log 'error :' + JSON.stringify error
      if response is undefined
        console.log 'error: ' + response

      callback { oauth_access_token, oauth_access_token_secret }

  postModel: (file, oauth_access_token, oauth_access_token_secret, callback) ->
      model_upload = fs.readFile file, (err, fileData) =>
        fileData = encodeURIComponent fileData.toString('base64')

        upload = JSON.stringify {
          file: fileData,
          fileName: file,
          hasRightsToModel: 1,
          acceptTermsAndConditions: 1,
          isPublic: false,
          isForSale: true,
          isDownloadable: true
        }

        @oa.post API_HOST+"/models/v1", oauth_access_token, oauth_access_token_secret, upload, (error, data, response) ->
          if error
            callback err, null
          else
            callback null, data

module.exports = ShapewaysClient
