from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import uvicorn
import asyncio
from src.tasks import create_and_download_requirements, celery_app
import os

from src.requirements_match import is_requirements_format
from src.ossaudit_custom import custom_cli

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

@app.websocket("/ws/vulnerability-check/{requirements}")
async def library_checker(websocket: WebSocket, requirements: str):
    print(f"Received requirements: {requirements}")
    await websocket.accept()
    file_name = 'requirements_2.txt'
    with open(file_name, 'w') as f:
       	lines = requirements.split()
        for line in lines:
            if is_requirements_format(line):
                f.write(line)
            else:
                raise ValueError("Wrong requirements format")
        
    try:
        resp = custom_cli(file_name=file_name)
        if "Found 0" in resp:
            await websocket.send_text("No vulnerabilities found")
        else:
            await websocket.send_text(resp)
    except Exception as e:
        await websocket.send_text(f"An error occurred: {str(e)}")
    finally:
        await websocket.close()

@app.websocket("/ws/console/{platform}/{python_version}/{requirements}")
async def websocket_endpoint(websocket: WebSocket, platform: str, python_version: str, requirements: str):
    await websocket.accept()

    try:
        # if platform
        task = create_and_download_requirements.delay(platform, python_version, requirements)
        
        # Ожидание завершения задачи
        while not task.ready():
            await websocket.send_text(f"Please wait. Task in queue...")
            await asyncio.sleep(5)
        
        # Получение результата
        if task.successful():
            zip_path = task.result
            await websocket.send_text("Task Done. Archive is ready.")
            print(zip_path)
            await websocket.send_text(f"/download/{os.path.basename(zip_path)}")
        else:
            raise Exception(task.info)
    except WebSocketDisconnect:
        print("WebSocket disconnected")

    except Exception as e:
        await websocket.send_text(f"An error occurred: {str(e)}")

    finally:
        await websocket.close()
        print(zip_path)
        for root, dirs, files in os.walk(f"/download/{os.path.basename(zip_path)}", topdown=False):
            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))
        
@app.get("/download/{zip_filename}")
async def download_file(zip_filename: str):
    zip_path = os.path.join(ZIP_STORAGE_DIR, zip_filename)
    if os.path.exists(zip_path):
        return FileResponse(zip_path, media_type='application/zip', filename=zip_filename)
    return {"error": "File not found"}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
