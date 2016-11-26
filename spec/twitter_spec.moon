
ltn12 = require "ltn12"

import to_json from require "lapis.util"

unpack = table.unpack or unpack

describe "twitter", ->
  it "creates a twitter client", ->
    import Twitter from require "twitter"
    Twitter {
      consumer_key: "xxx"
      consumer_secret: "xxx"
    }

  describe "with twitter client", ->
    local twitter
    local http_requests, responders

    before_each ->
      http_requests = {}
      responders = {}
      http = ->
        {
          request: (opts) ->
            table.insert http_requests, opts

            for k,v in pairs responders
              if opts.url\match k
                res, status = v!
                if opts.sink
                  opts.sink res
                  return "", status
                else
                  return res, status

            error opts
        }


      import Twitter from require "twitter"
      twitter = Twitter {
        :http
        consumer_key: "xxx"
        consumer_secret: "xxx"
      }

    it "get_user", ->
      responders["oauth2/token"] = =>
        to_json({
          access_token: "cool-zone"
        }), 200

      responders["users/show.json"] = =>
        "{}", 200

      out = twitter\get_user {
        screen_name: "leafo"
      }
      assert.same {}, out

    it "post_status", ->
      twitter.access_token = "hello"
      twitter.access_token_secret = "world"

      responders["statuses/update.json"] = => "{}", 200

      out = twitter\post_status status: "hi"
      assert.same {}, out


