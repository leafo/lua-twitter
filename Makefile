.PHONY: local lint build

local: build
	luarocks make --lua-version=5.1 --local twitter-dev-1.rockspec

build: 
	moonc twitter
 
lint:
	moonc -l twitter

