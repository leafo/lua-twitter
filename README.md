# twitter

[![Build Status](https://travis-ci.org/leafo/lua-twitter.svg?branch=master)](https://travis-ci.org/leafo/lua-twitter)


[![Actions Status](https://github.com/leafo/lua-twitter/workflows/test/badge.svg)](https://github.com/leafo/lua-twitter/actions)


A Lua library for working with the Twitter API.

This library is designed to work with either LuaSocket or OpenResty's
co-sockets via Lapis. If `ngx` is not in scope then the library will fall back
to LuaSocket for network.

`luasec` is required when using LuaSocket for `https` communication.

# Install

```bash
luarocks install https://luarocks.org/manifests/leafo/twitter-dev-1.rockspec
```

# Reference

Before getting started you'll need a *consumer key* and *consumer secret*. To
get those you'll need to create an app at <https://apps.twitter.com>.

## Application only authentication

There are a few ways to authenticate with the Twitter API. The easiest way is
to request without a user context using the cosnumer keys:

```lua
local Twitter = require("twitter").Twitter

local twitter = Twitter({
  consumer_key = "XXXXXXX",
  consumer_secret = "ABCABCABACABACACB"
})
```

This will allow you to run read-only API calls for public information.

If you want to do things like post statuses and upload images using the account
that owns the consumer keys then you can generate a access token and secret
from <https://apps.twitter.com> and use them like so:

```lua
local Twitter = require("twitter").Twitter

local twitter = Twitter({
  consumer_key = "XXXXXXX",
  consumer_secret = "ABCABCABACABACACB",
  access_token = "abcdefg-123456",
  access_token_secret = "awkeftSECretgwKWARKW"
})
```

## 3-Legged OAuth

If you want to add "Sign in with Twitter" then you can use this approach.

Create a new client with your consumer key and secret:

```lua
local Twitter = require("twitter").Twitter

local twitter = Twitter({
  consumer_key = "XXXXXXX",
  consumer_secret = "ABCABCABACABACACB"
})
```

Generate the URL to redirect the user to. (You should redirect their browser to this URL)

```lua
local url = twitter:sign_in_with_twitter_url()
```

After the user completes the sign in at the URL, they'll be redirect to the
callback URL on your website that you provided on the Twitter developers page.

The callback URL also some two query parameters attached to it: `oauth_token`
and `oauth_verifier`. You can use this information to create an access token
for the user:

```lua
local result = twitter:verify_sign_in_token(oauth_token, oauth_verifier)
```

The result is an object that looks approximately like this:

```json
{
  "oauth_token": "XXXXXXXX-XXXXXXXXXXXX",
  "oauth_token_secret": "XXXXXXXXXXXXXX",
  "user_id": "123434",
  "screen_name": "itchio",
  "x_auth_expires": "0"
}
```

You can now use the `oauth_token` and `oauth_token_secret` to create a new
Twitter client to make requests on their behalf. Use the same `consumer_key`
and `consumer_secret` as before:


```lua
local user_client = Twitter({
  access_token = result.oauth_token,
  access_token_secret = result.oauth_token_secret,

  consumer_key = "XXXXXXX",
  consumer_secret = "ABCABCABACABACACB"
})

user_client:post_status({ status = "Hello world!" })
```

# Methods

All of the following methods are available on an instance of the `Twitter`
class provided by the `twitter` module.

### `get_user(opts={})`

https://dev.twitter.com/rest/reference/get/users/show

Get information about a user

```lua
local user = twitter:get_user({
  screen_name = "moonscript"
})
```

### `get_user_timeline(opts={})`

https://dev.twitter.com/rest/reference/get/statuses/user_timeline

Get a page of tweets for a user's timeline.

```lua
local tweets = twitter:get_user_timeline({
  screen_name = "moonscript",
  include_rts = "0",
})
```

### `user_timeline_each_tweet(opts={})`

Returns an iterator to get every Tweet available in the API. Calls
`get_user_timeline` repeatedly, updating `max_id` accordingly.

Will set `count` to 200 if not specified.

```lua
for tweet in twitter:user_timeline_each_tweet({ screen_name = "moonscript" }) do
  print(tweet.text)
end
```

### `post_status(opts={})`

https://dev.twitter.com/rest/reference/post/statuses/update

Creates a new tweet for the user.

This requires authentication with a user context. You can get an access token
for your own account from <https://apps.twitter.com/>.

```lua
local user = assert(twitter:post_status({
  status = "Hello, this my tweet"
}))
```
### `post_media_upload(opts={})`

Uploads a image or video to Twitter, returns the media object. You can attach
the media object to a status update by including the id returned by this call
in the `post_status` method.

```lua
local media = assert(twitter:post_media_upload({
  filename = "mything.gif"
}))

assert(twitter:post_status {
  status = "feeling itchy pt. 3",
  media_ids = media.media_id_string
})
```

#### Uploading from URL

You can also upload an image directly from URL by passing in the URL of the
image to `url`.

```lua
local media = assert(twitter:post_media_upload({
  url: "http://leafo.net/hi.png"
}))
```

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  
License: MIT  

