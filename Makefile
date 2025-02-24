.PHONY: all
CONTAINER_NAME=centos
BUILD_PLATFORM=linux/amd64
PYTHON_VERSION=3.10.12
build:
	@if [ -n $$(docker images -a -q $(CONTAINER_NAME))]; then \
		echo "Image not exist, continue...";\
	else\
		echo "Image exist, deleting...";\
		docker rm $(CONTAINER_NAME);\
		docker rmi $(CONTAINER_NAME);\
    fi
	$(eval PYTHON_VERSION := $(shell read -p "Enter python version (format 3.8.17, minimum version 3.8.17):" input && echo $$input))
	@echo "Prepare to download: $(PYTHON_VERSION)"
	docker buildx build --platform $(BUILD_PLATFORM) --build-arg PYTON_VERSION=$(PYTHON_VERSION)  -t $(CONTAINER_NAME) .

.ONE_SHELL:
download:
	@if [ -n $$(docker images -a -q $(CONTAINER_NAME))]; then \
		make build;\
	else\
		echo "Image exist, continue...";\
    fi

	@if [ -n $$(docker ps -a -q -f name=$(CONTAINER_NAME))]; then \
		echo "Container not exist, continue...";\
	else\
		echo "Container exist, deleting...";\
		docker rm centos;\
    fi

	@read -p "Enter lib name and version (format "catboost" or "catboost==0.22" or empty for requirements.txt): " DOWNLOAD_LIBS; \
	if [ -z "$$DOWNLOAD_LIBS" ]; then \
	  	docker run -v ./requirements.txt:/home/requirements.txt --platform $(BUILD_PLATFORM) --name $(CONTAINER_NAME) $(CONTAINER_NAME) pip3 download -d mylib/ -r /home/requirements.txt;\
	else \
		docker run --platform $(BUILD_PLATFORM) --name $(CONTAINER_NAME) $(CONTAINER_NAME) pip3 download -d mylib/ $$DOWNLOAD_LIBS;\
	fi

	docker start -ai $(CONTAINER_NAME);
	rm -rf mylib;
	rm -rf mylib.zip;
	docker cp $(CONTAINER_NAME):mylib/ .;
	docker stop $(CONTAINER_NAME);
	zip mylib.zip mylib/*;


uninstall:
	docker rm $(CONTAINER_NAME);
	docker rmi $(CONTAINER_NAME);
	@echo "Done.";