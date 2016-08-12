
import encode_query_string, parse_query_string, from_json from require "lapis.util"
import hmac_sha1, encode_base64 from require "lapis.util.encoding"

-- luasocket's escape_uri function does not work, so we provide our own implementation
escape = ngx and ngx.escape_uri or (str) ->
  (str\gsub "([^A-Za-z0-9_%.-])", (c) -> "%%%02X"\format c\byte!)

ltn12 = require "ltn12"

generate_key = (...) ->
  unpack = table.unpack or _G.unpack
  import random from math

  random_char = ->
    switch random 1,3
      when 1
        random 65, 90
      when 2
        random 97, 122
      when 3
        random 48, 57


  generate_key = (length) -> string.char unpack [ random_char! for i=1,length ]
  generate_key ...

class Twitter
  api_url: "https://api.twitter.com"

  new: (@opts={}) =>
    @consumer_key = assert @opts.consumer_key, "missing consumer_key"
    @consumer_secret = assert @opts.consumer_secret, "missing consumer_secret"
    @http_provider = opts.http

  http: =>
    unless @_http
      @http_provider or= if ngx
        "lapis.nginx.http"
      else
        "ssl.https"

      @_http = if type(@http_provider) == "function"
        @http_provider!
      else
        require @http_provider

    @_http

  bearer_token: =>
    encode_base64 escape(@consumer_key) .. ":" .. escape(@consumer_secret)

  access_token: =>
    unless @_access_token
      @_access_token = assert @application_oauth_token!

    @_access_token

  oauth_signature:  (auth_params, token_secret, method, base_url, url_params={}, post_params={}) =>
    joined_params = {}

    for t in *{auth_params, url_params, post_params}
      for k, v in pairs t
        table.insert joined_params, {k,v}

    table.sort joined_params, (a,b) -> a[1] < b[1]

    joined_params = ["#{escape t[1]}=#{escape t[2]}" for t in *joined_params]
    joined_params = table.concat joined_params, "&"

    base_string = table.concat {
      method\upper!
      escape base_url
      escape joined_params
    }, "&"

    secret = escape(@consumer_secret) .. "&" .. escape(token_secret or "")

    encode_base64 hmac_sha1 secret, base_string

  oauth_auth_header: (token, ...) =>
    auth_params = {
      oauth_nonce: generate_key 40
      oauth_consumer_key: @consumer_key
      oauth_signature_method: "HMAC-SHA1"
      oauth_timestamp: tostring os.time!
      oauth_version: "1.0"
      oauth_token: token or "" -- don't have yet
    }

    auth_params.oauth_signature = @oauth_signature auth_params, ...

    buffer = {"OAuth "}

    for k, v in pairs auth_params
      table.insert buffer, escape k
      table.insert buffer, '="'
      table.insert buffer, escape v
      table.insert buffer, '"'
      table.insert buffer, ", "

    if buffer[#buffer] == ", "
      buffer[#buffer] = nil

    table.concat buffer

  http_request: (opts) =>
    if type(opts.source) == "string"
      opts.headers or= {}
      opts.headers["Content-Length"] = #opts.source
      opts.source = ltn12.source.string opts.source

    unless ngx
      -- for luasec
      opts.protocol = "sslv23"

    @http!.request opts

  -- The access token returned by this apparently never expires and never changes?
  application_oauth_token: (code) =>
    out = {}

    @http_request {
      url: "#{@api_url}/oauth2/token"
      method: "POST"
      sink: ltn12.sink.table out
      headers: {
        "Authorization": "Basic #{@bearer_token!}"
        "Content-Type": "application/x-www-form-urlencoded"
      }
      source: encode_query_string {
        grant_type: "client_credentials"
      }
    }

    out = table.concat out
    out = from_json out
    if out.errors
      return nil, out.errors[1].message

    out.access_token

  _request: (url, url_params) =>
    access_token = @access_token!

    out = {}
    url = "#{@api_url}#{url}"
    if url_params
      url ..= "?" .. encode_query_string url_params

    _, status = @http_request {
      :url
      method: "GET"
      sink: ltn12.sink.table out
      headers: {
        "Authorization": "Bearer #{access_token}"
      }
    }

    out = table.concat out
    out = from_json out
    out, status

  request_token: =>
    url = "#{@api_url}/oauth/request_token"

    url_params = { oauth_callback: @opts.oauth_callback }
    post_params = {}

    auth = @oauth_auth_header nil, nil, "POST", url, url_params, post_params

    url ..= "?" .. encode_query_string url_params if next url_params

    out = {}
    _, status = @http_request {
      :url
      method: "POST"
      sink: ltn12.sink.table out
      headers: {
        "Authorization": auth
      }
    }

    out = table.concat(out)

    unless status == 200
      return nil, out

    parse_query_string out

  status_update: (status) =>
    url = "#{@api_url}/1.1/statuses/update.json"
    url_params = { :status }
    post_params = {}

    auth = @oauth_auth_header "", "", "POST", url, url_params, post_params

    url ..= "?" .. encode_query_string url_params if next url_params

    out = {}
    _, status = @http_request {
      :url
      method: "POST"
      sink: ltn12.sink.table out
      headers: {
        "Authorization": auth
      }
    }

    table.concat(out), status

  get_user: (screen_name) =>
    @_request "/1.1/users/show.json", {
      include_entities: "false"
      screen_name: assert screen_name, "missing screen name"
    }

{ :Twitter }
