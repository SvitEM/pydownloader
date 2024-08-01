.PHONY: all
BUILD_PLATFORM ?= linux/amd64
PYTHON_VERSION ?= 3.8.10
CONTAINER_NAME = centos-$(PYTHON_VERSION)-$(shell echo $(BUILD_PLATFORM) | sed 's/\//-/g')
REQUIREMENTS_FILE ?= /home/requirements.txt
DOWNLOAD_LIBS = /home/requirements

build: 
	- rm -r home/*;
	- rm requirements.zip;
	@if [ -z "$$(docker images -q $(CONTAINER_NAME))" ]; then \
		echo "Image not exist, creating..."; \
		echo "Build platform: PYTHON VERSION $(PYTHON_VERSION) FOR PLATFORM $(BUILD_PLATFORM)"; \
		docker buildx build --platform $(BUILD_PLATFORM) --build-arg PYTHON_VERSION=$(PYTHON_VERSION) -t $(CONTAINER_NAME) .; \
	else \
		echo "Image exists, continue..."; \
	fi
	
	@echo "Copying requirements..."
	docker create --name temp_container $(CONTAINER_NAME) sleep 1; \
	docker cp tmp/requirements_libs.txt temp_container:$(REQUIREMENTS_FILE); \
	docker commit temp_container $(CONTAINER_NAME); \
	docker rm temp_container;

	@echo "Downloading libraries..."
	docker run --platform $(BUILD_PLATFORM) --name download_container $(CONTAINER_NAME) pip3 download -d $(DOWNLOAD_LIBS) -r $(REQUIREMENTS_FILE); 

	@echo "Creating archive..."
	docker start -ai download_container; 
	docker cp download_container:$(DOWNLOAD_LIBS) home/requirements; 
	docker cp download_container:$(REQUIREMENTS_FILE) home/requirements.txt; 
	docker rm download_container;
	zip -r requirements.zip home/*
	@echo "Done."
