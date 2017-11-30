local escape_uri
escape_uri = function(str)
  return (tostring(str):gsub("([^A-Za-z0-9._~-])", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end
local encode_query_string
encode_query_string = function(t, sep)
  if sep == nil then
    sep = "&"
  end
  local i = 0
  local buf = { }
  for k, v in pairs(t) do
    local _continue_0 = false
    repeat
      if type(k) == "number" and type(v) == "table" then
        k, v = v[1], v[2]
        if v == nil then
          v = true
        end
      end
      if v == false then
        _continue_0 = true
        break
      end
      buf[i + 1] = escape_uri(k)
      if v == true then
        buf[i + 2] = sep
        i = i + 2
      else
        buf[i + 2] = "="
        buf[i + 3] = escape_uri(v)
        buf[i + 4] = sep
        i = i + 4
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  buf[i] = nil
  return table.concat(buf)
end
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
local BigInt
do
  local _class_0
  local _base_0 = {
    is_zero = function(self)
      local _list_0 = self.bytes
      for _index_0 = 1, #_list_0 do
        local b = _list_0[_index_0]
        if b ~= 0 then
          return false
        end
      end
      return true
    end,
    to_decimal_string = function(self)
      local copy = self.__class({
        unpack(self.bytes)
      })
      local digits
      do
        local _accum_0 = { }
        local _len_0 = 1
        while not copy:is_zero() do
          local _, r = copy:div(10)
          local _value_0 = r
          _accum_0[_len_0] = _value_0
          _len_0 = _len_0 + 1
        end
        digits = _accum_0
      end
      return table.concat(digits):reverse()
    end,
    subtract = function(self, num)
      if num < 0 then
        return self:add(-num)
      end
      self.bytes[1] = (self.bytes[1] or 0) - num
      local k = 1
      while true do
        if not (self.bytes[k]) then
          break
        end
        while self.bytes[k] < 0 do
          if not (self.bytes[k + 1]) then
            break
          end
          local _update_0 = k + 1
          self.bytes[_update_0] = self.bytes[_update_0] - 1
          local _update_1 = k
          self.bytes[_update_1] = self.bytes[_update_1] + 256
        end
        k = k + 1
      end
      while self.bytes[#self.bytes] == 0 do
        self.bytes[#self.bytes] = nil
      end
      return self
    end,
    add = function(self, num)
      if num < 0 then
        return self:subtract(-num)
      end
      local k = 1
      while true do
        self.bytes[k] = (self.bytes[k] or 0) + num
        if self.bytes[k] < 256 then
          break
        end
        num = math.floor(self.bytes[k] / 256)
        self.bytes[k] = self.bytes[k] % 256
        k = k + 1
      end
      return self
    end,
    mul = function(self, mul)
      local last_idx = 1
      local r = 0
      for idx = 1, #self.bytes do
        local cur = self.bytes[idx] * mul + r
        self.bytes[idx] = cur % 256
        r = math.floor(cur / 256)
        last_idx = idx
      end
      if r > 0 then
        self.bytes[last_idx + 1] = r
      end
      return self
    end,
    div = function(self, div)
      local r
      for idx = #self.bytes, 1, -1 do
        local b = self.bytes[idx]
        if r then
          b = b + (r * 256)
        end
        local q
        q, r = math.floor(b / div), b % div
        self.bytes[idx] = q
      end
      return self, r
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, bytes)
      if bytes == nil then
        bytes = { }
      end
      self.bytes = bytes
    end,
    __base = _base_0,
    __name = "BigInt"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.from_decimal_string = function(self, str)
    local zero = ("0"):byte()
    local int = self()
    local _list_0 = {
      str:byte(1, -1)
    }
    for _index_0 = 1, #_list_0 do
      local b = _list_0[_index_0]
      local val = b - zero
      if next(int.bytes) then
        int:mul(10)
      end
      int:add(val)
    end
    return int
  end
  BigInt = _class_0
end
return {
  BigInt = BigInt,
  generate_key = generate_key,
  escape_uri = escape_uri,
  encode_query_string = encode_query_string
}
