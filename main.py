from fastapi import FastAPI, Request, Form, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from celery.result import AsyncResult
import uvicorn
import asyncio
from tasks import create_and_download_requirements, celery_app
import os

from requirements_match import is_requirements_format

app = FastAPI()

# Mount static files for serving CSS and other assets
app.mount("/static", StaticFiles(directory="static"), name="static")

# Set up templates
templates = Jinja2Templates(directory="templates")

# Константы
ZIP_STORAGE_DIR = 'zips'

@app.get("/", response_class=HTMLResponse)
async def read_form(request: Request):
    # Получаем количество задач в очереди
    task_count = celery_app.control.inspect().active()
    num_tasks = sum(len(v) for v in task_count.values()) if task_count else 0

    return templates.TemplateResponse("index.html", {"request": request, "num_tasks": num_tasks})

@app.websocket("/ws/console/{platform}/{python_version}/{requirements}")
async def websocket_endpoint(websocket: WebSocket, platform: str, python_version: str, requirements: str):
    await websocket.accept()

    try:
        # Очередь задачи через Celery
        if not is_requirements_format:
            raise ValueError("Wrong requirements format")
        # if platform
        task = create_and_download_requirements.delay(platform, python_version, requirements)
        
        # Ожидание завершения задачи
        while not task.ready():
            await websocket.send_text("Задача в очереди...")
            await asyncio.sleep(5)
        
        # Получение результата
        if task.successful():
            zip_path = task.result
            await websocket.send_text("Задача выполнена. Архив готов для скачивания.")
            await websocket.send_text(f"/download/{os.path.basename(zip_path)}")
        else:
            await websocket.send_text(f"Произошла ошибка при выполнении задачи.\n {task.info}")
    except WebSocketDisconnect:
        print("WebSocket disconnected")

    except Exception as e:
        await websocket.send_text(f"An error occurred: {str(e)}")

    finally:
        await websocket.close()
        for i in os.listdir('downloads'):
            os.remove(i)

@app.get("/download/{zip_filename}")
async def download_file(zip_filename: str):
    zip_path = os.path.join(ZIP_STORAGE_DIR, zip_filename)
    if os.path.exists(zip_path):
        return FileResponse(zip_path, media_type='application/zip', filename=zip_filename)
    return {"error": "Файл не найден"}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
