local encode_query_string, parse_query_string, from_json
do
  local _obj_0 = require("lapis.util")
  encode_query_string, parse_query_string, from_json = _obj_0.encode_query_string, _obj_0.parse_query_string, _obj_0.from_json
end
local hmac_sha1, encode_base64
do
  local _obj_0 = require("lapis.util.encoding")
  hmac_sha1, encode_base64 = _obj_0.hmac_sha1, _obj_0.encode_base64
end
local escape = ngx and ngx.escape_uri or function(str)
  return (str:gsub("([^A-Za-z0-9_%.-])", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end
local ltn12 = require("ltn12")
local generate_key
generate_key = function(...)
  local unpack = table.unpack or _G.unpack
  local random
  random = math.random
  local random_char
  random_char = function()
    local _exp_0 = random(1, 3)
    if 1 == _exp_0 then
      return random(65, 90)
    elseif 2 == _exp_0 then
      return random(97, 122)
    elseif 3 == _exp_0 then
      return random(48, 57)
    end
  end
  generate_key = function(length)
    return string.char(unpack((function()
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, length do
        _accum_0[_len_0] = random_char()
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)()))
  end
  return generate_key(...)
end
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
      return encode_base64(escape(self.consumer_key) .. ":" .. escape(self.consumer_secret))
    end,
    access_token = function(self)
      if not (self._access_token) then
        self._access_token = assert(self:application_oauth_token(), "failed to get access token")
      end
      return self._access_token
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
          _accum_0[_len_0] = tostring(escape(t[1])) .. "=" .. tostring(escape(t[2]))
          _len_0 = _len_0 + 1
        end
        joined_params = _accum_0
      end
      joined_params = table.concat(joined_params, "&")
      local base_string = table.concat({
        method:upper(),
        escape(base_url),
        escape(joined_params)
      }, "&")
      local secret = escape(self.consumer_secret) .. "&" .. escape(token_secret or "")
      return encode_base64(hmac_sha1(secret, base_string))
    end,
    oauth_auth_header = function(self, token, ...)
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
        table.insert(buffer, escape(k))
        table.insert(buffer, '="')
        table.insert(buffer, escape(v))
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
      local access_token = self:access_token()
      local out = { }
      url = tostring(self.api_url) .. tostring(url)
      if url_params then
        url = url .. ("?" .. encode_query_string(url_params))
      end
      local _, status = self:http_request({
        url = url,
        method = method,
        sink = ltn12.sink.table(out),
        headers = {
          ["Authorization"] = "Bearer " .. tostring(access_token)
        }
      })
      out = table.concat(out)
      out = from_json(out)
      return out, status
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
      local out = { }
      local _, status = self:http_request({
        url = url,
        method = method,
        sink = ltn12.sink.table(out),
        headers = {
          ["Authorization"] = auth
        }
      })
      out = table.concat(out)
      if not (status == 200) then
        return nil, out
      end
      return out
    end,
    request_token = function(self)
      local out = assert(self:_oauth_request("POST", tostring(self.api_url) .. "/oauth/request_token", {
        get = {
          oauth_callback = self.opts.oauth_callback
        }
      }))
      return parse_query_string(out)
    end,
    status_update = function(self, status)
      assert(status, "missing status")
      local out = assert(self:_oauth_request("POST", tostring(self.api_url) .. "/1.1/statuses/update.json", {
        access_token = assert(self.opts.access_token, "missing access token"),
        access_token_secret = self.opts.access_token_secret,
        get = {
          status = status
        }
      }))
      return from_json(out)
    end,
    get_user = function(self, screen_name)
      return self:_request("GET", "/1.1/users/show.json", {
        include_entities = "false",
        screen_name = assert(screen_name, "missing screen name")
      })
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.opts = opts
      self.consumer_key = assert(self.opts.consumer_key, "missing consumer_key")
      self.consumer_secret = assert(self.opts.consumer_secret, "missing consumer_secret")
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
