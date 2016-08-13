# twitter

[![Build Status](https://travis-ci.org/leafo/lua-twitter.svg?branch=master)](https://travis-ci.org/leafo/lua-twitter)

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

There are a few ways to authenticate with the Twitter API. The easiest way is
to request without a user context using your Twitter application keys.  You'll
need a `consumer_key` and `consumer_secret`

Create a Twitter API client like this: 

```lua
local Twitter = require("twitter").Twitter

local twitter = Twitter({
  consumer_key = "XXXXXXX",
  consumer_secret = "ABCABCABACABACACB"
})
```

### `get_user(opts={})`

https://dev.twitter.com/rest/reference/get/users/show

Get information about a user

```lua
local user = twitter:get_user({
  screen_name = "moonscript"
})
```

# `get_user_timeline(opts={})`

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
local user = twitter:post_status({
  access_token = "xxx",
  access_token_secret = "abcabcabcabcabc",
  status = "Hello, this my tweet"
})
```

# Contact

Author: Leaf Corcoran (leafo) ([@moonscript](http://twitter.com/moonscript))  
Email: leafot@gmail.com  
Homepage: <http://leafo.net>  
License: MIT  

