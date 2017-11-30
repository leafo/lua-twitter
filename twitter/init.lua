local parse_query_string, from_json
do
  local _obj_0 = require("lapis.util")
  parse_query_string, from_json = _obj_0.parse_query_string, _obj_0.from_json
end
local hmac_sha1, encode_base64
do
  local _obj_0 = require("lapis.util.encoding")
  hmac_sha1, encode_base64 = _obj_0.hmac_sha1, _obj_0.encode_base64
end
local escape_uri, encode_query_string
do
  local _obj_0 = require("twitter.util")
  escape_uri, encode_query_string = _obj_0.escape_uri, _obj_0.encode_query_string
end
local ltn12 = require("ltn12")
local Twitter
do
  local _class_0
  local _base_0 = {
    api_url = "https://api.twitter.com",
    http = function(self)
      if not (self._http) then
        self.http_provider = self.http_provider or (function()
          if ngx then
            return "lapis.nginx.http"
          else
            return "ssl.https"
          end
        end)()
        if type(self.http_provider) == "function" then
          self._http = self:http_provider()
        else
          self._http = require(self.http_provider)
        end
      end
      return self._http
    end,
    bearer_token = function(self)
      return encode_base64(escape_uri(self.consumer_key) .. ":" .. escape_uri(self.consumer_secret))
    end,
    get_access_token = function(self)
      if not (self.access_token) then
        self.access_token = assert(self:application_oauth_token(), "failed to get access token")
      end
      return self.access_token
    end,
    oauth_signature = function(self, auth_params, token_secret, method, base_url, url_params, post_params)
      if url_params == nil then
        url_params = { }
      end
      if post_params == nil then
        post_params = { }
      end
      local joined_params = { }
      local _list_0 = {
        auth_params,
        url_params,
        post_params
      }
      for _index_0 = 1, #_list_0 do
        local t = _list_0[_index_0]
        for k, v in pairs(t) do
          table.insert(joined_params, {
            k,
            v
          })
        end
      end
      table.sort(joined_params, function(a, b)
        return a[1] < b[1]
      end)
      do
        local _accum_0 = { }
        local _len_0 = 1
        for _index_0 = 1, #joined_params do
          local t = joined_params[_index_0]
          _accum_0[_len_0] = tostring(escape_uri(t[1])) .. "=" .. tostring(escape_uri(t[2]))
          _len_0 = _len_0 + 1
        end
        joined_params = _accum_0
      end
      joined_params = table.concat(joined_params, "&")
      local base_string = table.concat({
        method:upper(),
        escape_uri(base_url),
        escape_uri(joined_params)
      }, "&")
      local secret = escape_uri(self.consumer_secret) .. "&" .. escape_uri(token_secret or "")
      return encode_base64(hmac_sha1(secret, base_string))
    end,
    oauth_auth_header = function(self, token, ...)
      local generate_key
      generate_key = require("twitter.util").generate_key
      local auth_params = {
        oauth_nonce = generate_key(40),
        oauth_consumer_key = self.consumer_key,
        oauth_signature_method = "HMAC-SHA1",
        oauth_timestamp = tostring(os.time()),
        oauth_version = "1.0",
        oauth_token = token or ""
      }
      auth_params.oauth_signature = self:oauth_signature(auth_params, ...)
      local buffer = {
        "OAuth "
      }
      for k, v in pairs(auth_params) do
        table.insert(buffer, escape_uri(k))
        table.insert(buffer, '="')
        table.insert(buffer, escape_uri(v))
        table.insert(buffer, '"')
        table.insert(buffer, ", ")
      end
      if buffer[#buffer] == ", " then
        buffer[#buffer] = nil
      end
      return table.concat(buffer)
    end,
    http_request = function(self, opts)
      if type(opts.source) == "string" then
        opts.headers = opts.headers or { }
        opts.headers["Content-Length"] = #opts.source
        opts.source = ltn12.source.string(opts.source)
      end
      if not (ngx) then
        opts.protocol = "sslv23"
      end
      return self:http().request(opts)
    end,
    application_oauth_token = function(self, code)
      assert(self.consumer_key, "need consumer key to get application oauth token")
      local out = { }
      self:http_request({
        url = tostring(self.api_url) .. "/oauth2/token",
        method = "POST",
        sink = ltn12.sink.table(out),
        headers = {
          ["Authorization"] = "Basic " .. tostring(self:bearer_token()),
          ["Content-Type"] = "application/x-www-form-urlencoded"
        },
        source = encode_query_string({
          grant_type = "client_credentials"
        })
      })
      out = table.concat(out)
      out = from_json(out)
      if out.errors then
        return nil, out.errors[1].message
      end
      return out.access_token
    end,
    _request = function(self, method, url, url_params)
      url = tostring(self.api_url) .. tostring(url)
      local res, err
      if self.provided_access_token then
        res, err = self:_oauth_request(method, url, {
          get = url_params
        })
      else
        local access_token = self:get_access_token()
        if url_params then
          url = url .. ("?" .. encode_query_string(url_params))
        end
        local out = { }
        local _, status = self:http_request({
          url = url,
          method = method,
          sink = ltn12.sink.table(out),
          headers = {
            ["Authorization"] = "Bearer " .. tostring(access_token)
          }
        })
        res, err = table.concat(out)
      end
      if res then
        return from_json(res)
      else
        return res, err
      end
    end,
    _oauth_request = function(self, method, url, opts)
      if opts == nil then
        opts = { }
      end
      local url_params = opts.get or { }
      local post_params = opts.post or { }
      local access_token, access_token_secret
      access_token, access_token_secret = opts.access_token, opts.access_token_secret
      local auth = self:oauth_auth_header(access_token, access_token_secret, method, url, url_params, post_params)
      if next(url_params) then
        url = url .. ("?" .. encode_query_string(url_params))
      end
      local headers = {
        ["Authorization"] = auth
      }
      if opts.headers then
        for k, v in pairs(opts.headers) do
          headers[k] = v
        end
      end
      local body
      if opts.body then
        body = opts.body
      else
        body = encode_query_string(post_params)
      end
      if body then
        headers["Content-Length"] = #body
      end
      local out = { }
      local _, status = self:http_request({
        url = url,
        method = method,
        sink = ltn12.sink.table(out),
        source = body and ltn12.source.string(body) or nil,
        headers = headers
      })
      out = table.concat(out)
      if not (status == 200) then
        return nil, out ~= "" and out or "status " .. tostring(status)
      end
      return out
    end,
    request_token = function(self, opts)
      local out, err = self:_oauth_request("POST", tostring(self.api_url) .. "/oauth/request_token", {
        get = {
          oauth_callback = opts and opts.oauth_callback or self.opts.oauth_callback
        }
      })
      if out then
        return parse_query_string(out)
      else
        return out, err
      end
    end,
    sign_in_with_twitter_url = function(self)
      local tokens, err = self:request_token()
      if not (tokens) then
        return nil, err
      end
      local url = "https://api.twitter.com/oauth/authenticate?" .. encode_query_string({
        force_login = "true",
        oauth_token = tokens.oauth_token
      })
      return url, tokens
    end,
    verify_sign_in_token = function(self, oauth_token, oauth_verifier)
      local res, status = self:_oauth_request("POST", tostring(self.api_url) .. "/oauth/access_token", {
        access_token = oauth_token,
        headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded"
        },
        post = {
          oauth_verifier = oauth_verifier
        }
      })
      if res then
        return parse_query_string(res)
      else
        return nil, status
      end
    end,
    post_status = function(self, opts)
      if opts == nil then
        opts = { }
      end
      assert(opts.status, "missing status")
      local out = assert(self:_oauth_request("POST", tostring(self.api_url) .. "/1.1/statuses/update.json", {
        access_token = assert(opts.access_token or self.access_token, "missing access token"),
        access_token_secret = opts.access_token_secret or self.access_token_secret,
        get = opts
      }))
      return from_json(out)
    end,
    post_media_upload = function(self, opts)
      if opts == nil then
        opts = { }
      end
      local File, StringFile, encode_multipart
      do
        local _obj_0 = require("twitter.multipart")
        File, StringFile, encode_multipart = _obj_0.File, _obj_0.StringFile, _obj_0.encode_multipart
      end
      local file
      if opts.url then
        local out = { }
        local protocol
        if opts.url:match("^https") and self.http_provider == "ssl.https" then
          protocol = "sslv23"
        end
        local success, status = assert(self:http().request({
          url = opts.url,
          sink = ltn12.sink.table(out),
          method = "GET",
          protocol = protocol
        }))
        if status ~= 200 then
          return nil, "got bad status when fetching media: " .. tostring(status)
        end
        local filename = opts.filename or opts.url:match("[^/]+%.%w+$")
        file = StringFile(table.concat(out), assert(filename, "failed to extract filename from url"))
      else
        file = File(assert(opts.filename, "missing file"))
      end
      local body, boundary = encode_multipart({
        media = file
      })
      local out = assert(self:_oauth_request("POST", "https://upload.twitter.com/1.1/media/upload.json", {
        access_token = assert(opts.access_token or self.access_token, "missing access token"),
        access_token_secret = opts.access_token_secret or self.access_token_secret,
        body = body,
        headers = {
          ["Content-Type"] = "multipart/mixed; boundary=" .. tostring(boundary)
        }
      }))
      return from_json(out)
    end,
    get_user = function(self, opts)
      return self:_request("GET", "/1.1/users/show.json", opts)
    end,
    get_user_timeline = function(self, opts)
      return self:_request("GET", "/1.1/statuses/user_timeline.json", opts)
    end,
    user_timeline_each_tweet = function(self, opts)
      if opts == nil then
        opts = { }
      end
      opts.count = opts.count or 200
      local opts_clone
      do
        local _tbl_0 = { }
        for k, v in pairs(opts) do
          _tbl_0[k] = v
        end
        opts_clone = _tbl_0
      end
      return coroutine.wrap(function()
        while true do
          local last_tweet
          local _list_0 = self:get_user_timeline(opts_clone)
          for _index_0 = 1, #_list_0 do
            local tweet = _list_0[_index_0]
            coroutine.yield(tweet)
            last_tweet = tweet
          end
          if not (last_tweet) then
            break
          end
          local last_id = last_tweet.id_str
          local BigInt
          BigInt = require("twitter.util").BigInt
          local id_int = BigInt:from_decimal_string(last_id)
          id_int:add(-1)
          opts_clone.max_id = id_int:to_decimal_string()
        end
      end)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
      if self.opts.access_token or self.opts.access_token_secret then
        self.access_token = assert(self.opts.access_token, "missing access token")
        self.access_token_secret = assert(self.opts.access_token_secret, "missing access_token_secret")
        self.provided_access_token = true
      end
      if self.opts.consumer_key or self.opts.consumer_secret then
        self.consumer_key = assert(self.opts.consumer_key, "missing consumer_key")
        self.consumer_secret = assert(self.opts.consumer_secret, "missing consumer_secret")
      end
      self.http_provider = opts.http
    end,
    __base = _base_0,
    __name = "Twitter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Twitter = _class_0
end
return {
  Twitter = Twitter
}
