import subprocess

def run_makefile(target=None):
    try:
        # Define the command to run the Makefile
        command = ['make']
        if target:
            command += target.split(' ')

        # Open the subprocess and run the Makefile
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

        # Continuously read from stdout and print each line immediately
        print("Standard Output:")
        while True:
            line = process.stdout.readline()
            if not line:  # If line is empty, end of stream
                break
            print(line.strip())  # Strip to remove extra newline
            line = process.stdout.readline()
            if line:  # If line is empty, end of stream
                line = line.strip()
                if "requirements" not in line.strip():
                    print(line)  # Strip to remove extra newline
        # Read and print any errors from stderr after process completion
        # stderr = process.stderr.read()
        # if stderr:
        #     print("Standard Error:")
        #     print(stderr.strip())

        # Wait for the process to finish and check the return code
        return_code = process.wait()
        if return_code == 0:
            print("Makefile ran successfully.")
        else:
            print(f"Makefile failed with return code {return_code}.")

    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
run_makefile("build BUILD_PLATFORM=linux/amd64 PYTHON_VERSION=3.8.15")  # To run the default target
# run_makefile('clean')  # To run a specific target, e.g., 'clean'
