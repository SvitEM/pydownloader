from fastapi import FastAPI, Request, Form, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import re
import subprocess
import uvicorn
import asyncio
from requirements_match import is_requirements_format
import urllib.parse

app = FastAPI()

# Mount static files for serving CSS and other assets
app.mount("/static", StaticFiles(directory="static"), name="static")

# Set up templates
templates = Jinja2Templates(directory="templates")


def prep_input_data(platform: str, python_version: str, requirements, str) -> list:
    if platform not in platforms_list:
        platform = None
    major, minor, _ = python_version.split('.')
    if int(major) != 3 or int(minor) < 8:
        python_version = None
    return platform, python_version
        
@app.get("/", response_class=HTMLResponse)
async def read_form(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.websocket("/ws/console/{platform}/{python_version}/{requirements}")
async def websocket_endpoint(websocket: WebSocket, platform: str, python_version: str, requirements: str):
    requirements_file = "home/requirements_libs.txt"
    await websocket.accept()

    try:
        # Define the command to run the Makefil
        platform = '/'.join(platform.split('%0A'))
        print(platform)

        # Validate input data
        platform, python_version = prep_input_data(platform, python_version)
        if not platform:
            raise ValueError(f"This script does not work on {platform} platform. Use platform from supported list.")
        if not python_version:
            raise ValueError(f"This script does not work on Python {python_version}. The minimum supported Python version is 3.8.")

        with open(requirements_file, 'w+') as f:
            for lib_name in requirements.split('\n'):
                if is_requirements_format(lib_name):
                    f.write(requirements)


        command = ['make', f"BUILD_PLATFORM={platform}", f"PYTHON_VERSION={python_version}", f"REQUIREMENTS_FILE={requirements_file}"]

        # Open the subprocess and run the Makefile
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Continuously read from stdout and print each line immediately
        while True:
            line = process.stdout.readline()
            if not line:
                break
            await websocket.send_text(line.strip())  # Strip to remove extra newline
            
            line = process.stdout.readline()
            if line: 
                line = line.strip()
                if "requirements" not in line.strip():
                    await websocket.send_text(line.strip())  # Strip to remove extra newline

        # Wait for the process to finish and check the return code
        return_code = process.wait()
        if return_code == 0:
            print("Makefile ran successfully.")
        else:
            print(f"Makefile failed with return code {return_code}.")

    except WebSocketDisconnect:
        print("WebSocket disconnected")

    except Exception as e:
        await websocket.send_text(f"An error occurred: {str(e)}")

    finally:
        await websocket.close()

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, 
                # ssl_keyfile="key.pem", ssl_certfile="cert.pem"
                )
