package = "twitter"
version = "dev-1"

source = {
  url = "git://github.com/leafo/lua-twitter.git",
}

description = {
  summary = "",
  homepage = "https://github.com/leafo/lua-twitter",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "luasocket",
  "lua-cjson",
  "luasec",
}

build = {
  type = "builtin",
  modules = {
		["twitter"] = "twitter/init.lua",
  }
}

