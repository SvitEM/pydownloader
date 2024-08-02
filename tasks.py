# tasks.py

from celery import Celery
import subprocess
import os
import shutil
import zipfile
import time
import uuid
import logging

# Константы
DOWNLOAD_DIR = 'downloads'
REQUIREMENTS_DIR = 'requirements'
ZIP_STORAGE_DIR = 'zips'

# Убедитесь, что все необходимые директории существуют
os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(ZIP_STORAGE_DIR, exist_ok=True)

# Создаем приложение Celery
celery_app = Celery('tasks', broker='redis://localhost:6379/0', backend='redis://localhost:6379/1')

@celery_app.task
def create_and_download_requirements(platform: str, python_version: str, requirements: str):
    # Уникальный идентификатор для текущей задачи
    task_id = str(uuid.uuid4())
    task_download_dir = os.path.join(DOWNLOAD_DIR, task_id)

    # Подготовка команд
    requirements_file = os.path.join(task_download_dir, 'requirements.txt')
    os.makedirs(task_download_dir, exist_ok=True)

    with open(requirements_file, 'w') as f:
        f.write(requirements)

    # Команда make для скачивания библиотек
    platform = platform.replace("%0A", "/")

    command = ['make', 
               f"BUILD_PLATFORM={platform}", 
               f"PYTHON_VERSION={python_version}", 
               f"REQUIREMENTS_FILE_PATH={task_download_dir}"]

    # Запуск процесса make
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    #  Continuously read from stdout and print each line immediately
    errors = []
    while True:
        line = process.stdout.readline()
        if line:
            logging.info(line.strip())  # Strip to remove extra newline
        
        line_err = process.stderr.readline()
        if line_err: 
            # if "No matching distribution found" in line_err.strip():
            #     raise ValueError(f'')
            errors.append(line_err.strip())
            logging.error(line_err.strip())  # Strip to remove extra newline
        if not line or not line_err:
            break

    # Wait for the process to finish and check the return code
    return_code = process.wait()
    if return_code == 0:
        print("Makefile ran successfully.")
    else:
        nl = '\n'
        raise ValueError(f"""Makefile failed with return code {return_code}. {nl.join(errors)}""")

    # Создание zip архива
    zip_filename = os.path.join(ZIP_STORAGE_DIR, f"requirements_{task_id}.zip")
    with zipfile.ZipFile(zip_filename, 'w') as zipf:
        for foldername, subfolders, filenames in os.walk(task_download_dir):
            for filename in filenames:
                file_path = os.path.join(foldername, filename)
                zipf.write(file_path, os.path.relpath(file_path, task_download_dir))

    # Удаление временных файлов
    shutil.rmtree(task_download_dir)

    # Возвращаем путь к zip файлу
    return zip_filename

# Задача удаления файлов старше одного часа
@celery_app.task
def cleanup_old_zips():
    current_time = time.time()
    for filename in os.listdir(ZIP_STORAGE_DIR):
        file_path = os.path.join(ZIP_STORAGE_DIR, filename)
        if os.path.isfile(file_path):
            file_creation_time = os.path.getctime(file_path)
            # Если файл старше одного часа, удаляем его
            if current_time - file_creation_time > 3600:
                os.remove(file_path)

# Настройка периодической задачи для очистки старых zip файлов
from celery.schedules import crontab

celery_app.conf.beat_schedule = {
    'cleanup-old-zips-every-hour': {
        'task': 'tasks.cleanup_old_zips',
        'schedule': crontab(minute=0, hour='*'),  # каждый час
    },
}
