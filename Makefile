# Target to setup the environment
setup:
	python3.11 -m venv venv;
	# Activate the virtual environment
	source venv/bin/activate;
	# Install Python dependencies from requirements.txt
	python3.11 -m pip install -r requirements.txt;

# Default target to start all services
start: start_redis start_uvicorn start_celery_worker1 start_celery_worker2

start_redis:
	source venv/bin/activate;
	@if [ -z "docker images -q redis_pydownloder" ]; then \
		echo "Image not exist, creating..."; \
		docker run -d --name redis_pydownloder -p 6379:6379 redis/redis-stack-server:latest;\
	else \
		echo "Image exists, continue..."; \
		docker start redis_pydownloder;\
	fi

# Target to start Uvicorn
start_uvicorn:
	uvicorn main:app --reload --port 8000 --workers 1 &

# Target to start Celery Worker 1
start_celery_worker1:
	celery -A tasks.celery_app worker --loglevel=info &

# Target to start Celery Worker 2
start_celery_worker2:
	celery -A tasks.celery_app beat --loglevel=info &

# Target to stop all background processes (optional)
.PHONY: stop
stop:
	pkill -f "uvicorn main:app"
	pkill -f "celery"
	docker stop redis_pydownloder