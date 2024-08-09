.PHONY: all
BUILD_PLATFORM ?= linux/amd64
PYTHON_VERSION ?= 3.8.17

CONTAINER_NAME = centos-$(PYTHON_VERSION)-$(BUILD_PLATFORM)
REQUIREMENTS_FILE_PATH ?= downloads/dcd7f7f1-a2c3-4296-8d13-5c693d2d6271
DOWNLOAD_LIBS = /home/requirements

build: 
	- docker rm download_container;
	@if [ -z "$$(docker images -q $(CONTAINER_NAME))" ]; then \
		echo "Image not exist, creating..."; \
		echo "Build platform: PYTHON VERSION $(PYTHON_VERSION) FOR PLATFORM $(BUILD_PLATFORM)"; \
		docker buildx build --platform $(BUILD_PLATFORM) --build-arg PYTHON_VERSION=$(PYTHON_VERSION) -t $(CONTAINER_NAME) .; \
	else \
		echo "Image exists, continue..."; \
	fi
	
	@echo "Copying requirements..."
	docker create --name temp_container $(CONTAINER_NAME);
	docker cp $(REQUIREMENTS_FILE_PATH)/requirements.txt temp_container:$(DOWNLOAD_LIBS)/requirements.txt;
	docker commit temp_container $(CONTAINER_NAME); 
	docker rm temp_container;

	@echo "Downloading libraries..."
	docker run --platform $(BUILD_PLATFORM) --name download_container $(CONTAINER_NAME) pip3 download -d $(DOWNLOAD_LIBS) -r $(DOWNLOAD_LIBS)/requirements.txt; 

	@echo "Creating archive..."
	docker start -ai download_container; 
	docker cp download_container:$(DOWNLOAD_LIBS)/. $(REQUIREMENTS_FILE_PATH); 
	docker rm download_container;
	@echo "Done."
