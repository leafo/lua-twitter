describe "twitter.multipart", ->
  import encode_multipart, File, StringFile from require "twitter.multipart"

  describe "encode_multipart", ->
    it "encodes basic table", ->
      payload, boundary = encode_multipart { hello: "world" }
      assert.truthy payload
      assert.truthy boundary

      assert.same table.concat({
        "--#{boundary}"
        'Content-Disposition: form-data; name="hello"'
        ""
        "world"
        "--#{boundary}--"
        ""
      }, "\r\n"), payload

    it "encodes file from string", ->
      file = StringFile "filecontents", "test.txt"
      payload, boundary = encode_multipart {
        {"hello", "world"}
        {"the_file", file}
      }

      assert.truthy payload
      assert.truthy boundary

      assert.same table.concat({
        "--#{boundary}"
        'Content-Disposition: form-data; name="hello"'
        ""
        "world"
        "--#{boundary}"
        'Content-Disposition: form-data; name="the_file"; filename="test.txt"'
        'Content-type: text/plain'
        ""
        "filecontents"
        "--#{boundary}--"
        ""
      }, "\r\n"), payload

