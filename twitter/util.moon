-- luasocket's escape_uri & ngix's function doesn't work with twitter api, so we provide our own implementation
escape_uri = (str) ->
  (str\gsub "([^A-Za-z0-9_%.-])", (c) -> "%%%02X"\format c\byte!)

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


class BigInt
  @from_decimal_string: (str) =>
    zero = "0"\byte!

    int = @!

    for b in *{ str\byte 1, -1 }
      val = b - zero
      int\mul 10 if next int.bytes
      int\add val

    int

  new: (@bytes={}) =>

  is_zero: =>
    for b in *@bytes
      return false if b != 0

    true

  to_decimal_string: =>
    copy = @@ { unpack @bytes }
    digits = while not copy\is_zero!
      _, r = copy\div 10
      r

    table.concat(digits)\reverse!

  subtract: (num) =>
    return @add -num if num < 0

    @bytes[1] = (@bytes[1] or 0) - num

    k =1
    while true
      break unless @bytes[k]
      while @bytes[k] < 0
        break unless @bytes[k + 1]
        @bytes[k + 1] -= 1
        @bytes[k] += 256

      k += 1

    while @bytes[#@bytes] == 0
      @bytes[#@bytes] = nil

    @

  add: (num) =>
    return @subtract -num if num < 0

    k = 1
    while true
      @bytes[k] = (@bytes[k] or 0) + num
      break if @bytes[k] < 256

      -- add overflow
      num = math.floor @bytes[k] / 256
      @bytes[k] = @bytes[k] % 256
      k += 1

    @

  -- mul must be < 256
  mul: (mul) =>
    last_idx = 1
    r = 0
    for idx=1,#@bytes
      cur = @bytes[idx] * mul + r
      @bytes[idx] = cur % 256
      r = math.floor cur / 256
      last_idx = idx

    if r > 0
      @bytes[last_idx + 1] = r

    @

  -- div must be < 256
  div: (div) =>
    local r
    for idx=#@bytes,1,-1
      b = @bytes[idx]
      b += r * 256 if r
      q, r = math.floor(b / div), b % div
      @bytes[idx] = q

    @, r

{:BigInt, :generate_key, :escape_uri}

