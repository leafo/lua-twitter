
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

            error {
              "Got an http request that we didn't stub"
              opts
            }
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

    describe "oauth login", ->
      it "sign_in_with_twitter_url", ->
        responders["oauth/request_token"] = =>
          "oauth_token=hello-world", 200

        url = twitter\sign_in_with_twitter_url!
        assert.same "https://api.twitter.com/oauth/authenticate?force_login=true&oauth_token=hello%2dworld", url

      it "verify_sign_in_token", ->
        responders["oauth/access_token"] = =>
          "hello=world", 200

        result = twitter\verify_sign_in_token "hello-world", "some-verifier"

        assert.same {
          {"hello", "world"}
          hello: "world"
        }, result

        request = assert unpack http_requests
        assert.same "https://api.twitter.com/oauth/access_token", request.url

