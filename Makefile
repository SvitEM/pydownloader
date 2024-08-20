# Target to setup the environment and install requirements
.PHONY: setup
setup:
	python3.11 -m venv venv
	. venv/bin/activate && pip install -r requirements.txt

# Default target to start all services
.PHONY: start
start: start_redis start_uvicorn start_celery_worker start_celery_beat

.PHONY: start_redis
start_redis:
	@if [ -z "docker images -q redis_pydownloder" ]; then \
			echo "Image does not exist, creating..."; \
			docker run -d --name redis_pydownloder -p 6379:6379 redis/redis-stack-server:latest; \
	else \
			echo "Image exists, starting container..."; \
			docker start redis_pydownloder; \
	fi

# Target to start Uvicorn
.PHONY: start_uvicorn
start_uvicorn:
	. venv/bin/activate && uvicorn main:app --reload --port 8000 --workers 1 &

# Target to start Celery Worker
.PHONY: start_celery_worker
start_celery_worker:
	. venv/bin/activate && celery -A src.tasks.celery_app worker --loglevel=info &

# Target to start Celery Beat
.PHONY: start_celery_beat
start_celery_beat:
	. venv/bin/activate && celery -A src.tasks.celery_app beat --loglevel=info &

# Target to stop all background processes
.PHONY: stop
stop:
	pkill -f "uvicorn main:app" &
	pkill -f "celery" &
	docker stop redis_pydownloder