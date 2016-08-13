

describe "twitter.util", ->
  describe "BigInt", ->
    import BigInt from require "twitter.util"

    it "adds number", ->
      num = BigInt\from_decimal_string "0"
      num\add 5
      assert.same "5", num\to_decimal_string!

    it "subtracts big number", ->
      num = BigInt {0,0,0,0,0,0,0,0,1}

      assert.same "18446744073709551616", num\to_decimal_string!
      num\subtract 5
      assert.same {251,255,255,255,255,255,255,255}, num.bytes
      assert.same "18446744073709551611", num\to_decimal_string!




