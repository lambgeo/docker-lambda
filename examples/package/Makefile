SHELL = /bin/bash

package:
	docker build --tag package:latest .
	docker run --name lambda -w /var/task --volume $(shell pwd)/:/local -itd package:latest bash
	docker cp lambda:/tmp/package.zip package.zip
	docker stop lambda
	docker rm lambda

clean:
	docker stop lambda
	docker rm lambda
