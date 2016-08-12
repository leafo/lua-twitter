.PHONY: local lint build

local: build
	luarocks make --local twitter-dev-1.rockspec

build: 
	moonc twitter
 
lint:
	moonc -l twitter

