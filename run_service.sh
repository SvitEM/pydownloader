#!/bin/bash


cd /home/vps/pydownloader || exit

# Function to start Redis container
start_redis() {
    if [ -z "docker images -q redis_pydownloder" ]; then
        echo "Image does not exist, creating..."
        docker run -d --name redis_pydownloder -p 6379:6379 redis/redis-stack-server:latest
    else
        echo "Image exists, starting container..."
        docker start redis_pydownloder
    fi
}

# Function to start Uvicorn
start_uvicorn() {
    echo "Starting Uvicorn server..."
    source venv/bin/activate
    python3.11 -m uvicorn main:app --port 8032 --workers 2 &
    UVICORN_PID=$!
}

# Function to start Celery worker
start_celery_worker() {
    echo "Starting Celery worker..."
    source venv/bin/activate
    celery -A src.tasks.celery_app worker --loglevel=info &
    CELERY_WORKER_PID=$!
}

# Function to start Celery beat
start_celery_beat() {
    echo "Starting Celery beat..."
    source venv/bin/activate
    celery -A src.tasks.celery_app beat --loglevel=info &
    CELERY_BEAT_PID=$!
}

# Function to stop all background processes
stop_services() {
    echo "Stopping Uvicorn server, Celery workers, and Redis container..."
    pkill -f "uvicorn main:app"
    pkill -f "celery"
    docker stop redis_pydownloder
}

# Start the services
start_redis
start_uvicorn
start_celery_worker
start_celery_beat

echo "All services started successfully."

# Wait for processes to finish
wait $UVICORN_PID $CELERY_WORKER_PID $CELERY_BEAT_PID
