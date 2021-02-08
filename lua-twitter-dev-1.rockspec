package = "lua-twitter"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lua-twitter.git",
}

description = {
  summary = "A Lua twitter library that works with OpenResty or LuaSocket",
  homepage = "https://github.com/leafo/lua-twitter",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "luasocket",
  "lua-cjson",
  "luasec",
  "lapis",
}

build = {
  type = "builtin",
  modules = {
    ["twitter"] = "twitter/init.lua",
    ["twitter.multipart"] = "twitter/multipart.lua",
    ["twitter.util"] = "twitter/util.lua",
  }
}

