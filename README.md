
# CS402M Face Authentication System

## A Red-Team Proof of Concept for Targeted Payload Delivery

---

## 📌 Project Overview

This project is a proof-of-concept face authentication application developed as part of the Computer Systems Security (CS402M) course at IIT Tirupati. The system behaves normally for authorised users but silently triggers a ransomware simulator when a designated target person is recognised.

**Key Features:**
- Synthetic dataset generation from a single reference image using Stable Diffusion
- MobileNetV3Large-based face classifier with 98.17% test accuracy
- Android application with TensorFlow Lite integration
- Two authentication paths: Class A (authorised) and Class B (target)
- Pull-based ransomware simulation using AES-256-CBC encryption
- Full demonstration in an Android emulator

---

## 📂 Repository Structure
```CS402M-Face-Authentication/
│
├── dataset/ # Synthetic face dataset
│ ├── Class_A/
│ │ ├── teammate1/
│ │ │ ├── train/ (400 images)
│ │ │ ├── val/ (50 images)
│ │ │ └── test/ (50 images)
│ │ └── teammate2/
│ │ ├── train/ (400 images)
│ │ ├── val/ (50 images)
│ │ └── test/ (50 images)
│ └── Class_B/
│ └── professor/
│ ├── train/ (400 images)
│ ├── val/ (50 images)
│ └── test/ (50 images)
│
├── face_auth_ransomware_copy/ # Flutter Android Application
│ ├── lib/
│ │ ├── main.dart # App entry point
│ │ ├── auth_screen.dart # Camera + authentication logic
│ │ ├── home_screen.dart # Success screen (Class A)
│ │ ├── ransom_note_screen.dart # Ransom note UI (Class B)
│ │ └── models/
│ │ ├── face_recognition_model.dart # TFLite inference
│ │ └── ransomware_engine.dart # Payload pull & execution
│ └── pubspec.yaml
│
├── training_css.py # Model training script
├── ransom_payload.py # Ransomware payload (pulled from GitHub)
├── face_classifier_float32.tflite # Converted TFLite model (2.35 MB)
├── face_classifier_labels.txt # Class labels
└── README.md # This file
```
---

## 🧠 Dataset Generation

We used **Stable Diffusion v1.5** in image-to-image (img2img) mode to generate synthetic facial variations from a single reference photo per identity. Each input image was augmented with **25% probability** during generation before being passed to the diffusion model.

### Generation Parameters

| Parameter | Value |
|-----------|-------|
| Base model | `runwayml/stable-diffusion-v1-5` |
| Pipeline | `StableDiffusionImg2ImgPipeline` |
| Strength | 0.20 |
| Guidance scale | 7.0 |
| Inference steps | 30 |
| Images per identity | 500 (generated directly) |
| Total images | 1,500 (3 identities × 500) |
| Negative prompt | "different person, different facial structure, deformed face, blurry, cartoon, plastic skin, exaggerated aging" |

### Prompt Categories

Random combinations were sampled from:
- **Age:** young adult, middle-aged, elderly (6 options)
- **Lighting:** natural morning, bright indoor, dim indoor (8 options)
- **Pose:** front-facing, three-quarter view left/right (6 options)
- **Background:** plain wall, office, classroom, outdoor (7 options)
- **Expression:** neutral, subtle smile, serious (6 options)
- **Camera style:** DSLR, smartphone, studio (6 options)
- **Clothing:** t-shirt, collared shirt, jacket (5 options)

### Dataset Split

| Identity | Train | Validation | Test | Total |
|----------|-------|------------|------|-------|
| Teammate1 | 400 | 50 | 50 | 500 |
| Teammate2 | 400 | 50 | 50 | 500 |
| Professor | 400 | 50 | 50 | 500 |
| **Total** | **1,200** | **150** | **150** | **1,500** |

**Dataset Tag:** `v1.0-dataset`

---

## 🤖 Model Training

### Architecture

- **Backbone:** MobileNetV3Large (ImageNet pretrained)
- **Input size:** 224 × 224 × 3 (RGB)
- **Dropout:** 0.40
- **Classification Head:** 3 units with softmax and L2 regularisation

### Training Strategy (Two-Stage Fine-Tuning)

| Parameter | Stage 1 | Stage 2 |
|-----------|---------|---------|
| Backbone | Frozen | Unfrozen (last 35 layers) |
| Learning rate | 1×10⁻³ | 1×10⁻⁵ |
| Weight decay | 1×10⁻⁴ | 1×10⁻⁵ |
| Optimizer | AdamW | AdamW |
| Max epochs | 30 | 20 |
| Early stopping patience | 7 | 7 |
| LR reduction factor | 0.3 | 0.3 |

### Model Performance

| Metric | Validation | Test |
|--------|------------|------|
| Accuracy | 97.33% | **98.17%** |
| Top-2 Accuracy | 99.33% | 99.33% |
| Loss | 0.0874 | 0.0652 |

### Classification Report (Test Set)

| Class | Precision | Recall | F1-Score | Support |
|-------|-----------|--------|----------|---------|
| teammate1 | 0.9800 | 0.9800 | 0.9800 | 50 |
| teammate2 | 0.9800 | 0.9600 | 0.9697 | 50 |
| professor | 0.9800 | 1.0000 | 0.9899 | 50 |
| **Weighted Avg** | **0.9800** | **0.9800** | **0.9799** | **150** |

---

## 📱 Flutter Application

### Authentication Paths

**Path A: Authentication Successful (Class A)**
1. Camera captures a frame
2. Face detection using OpenCV's Haar cascade
3. TFLite model predicts class and confidence
4. If `teammate1` or `teammate2` with confidence > 0.85:
   - Display "Authentication successful"
   - Log timestamp to `auth_log.txt`
   - Navigate to `HomeScreen`

**Path B: Target Detected (Class B)**
1. Same preprocessing steps
2. If `professor` with confidence > 0.85:
   - Pull ransomware payload from GitHub: `ransom_payload.py`
   - Execute AES-256-CBC encryption on files in `/storage/emulated/0/`
   - Skip protected Android directories (`Android/data`, `Android/obb`, `Android/media`)
   - Save encryption key to `encryption_key.key`
   - Create `ransomware_manifest.txt` with timestamp, encrypted file list
   - Display full-screen ransom note UI

### TensorFlow Lite Model

- **File:** `face_classifier_float32.tflite`
- **Size:** 2.35 MB
- **Labels:** `face_classifier_labels.txt`
- **Inference time:** ~45 ms/frame on emulator

### Ransomware Payload URL
https://raw.githubusercontent.com/Dhyanam2005/CS402M-Face-Authentication/main/ransom_payload.py

---

## 🚀 Getting Started

### Prerequisites

- Python 3.10+
- TensorFlow 2.15+
- Flutter 3.16+
- Android Studio / Android Emulator

### Training the Model

```bash
# Install dependencies
pip install tensorflow scikit-learn matplotlib

# Run training script
python training_css.py
Running the Flutter App
bash
cd face_auth_ransomware_copy
flutter pub get
flutter run
```

### 📊 Results Summary
- Metric	Value
- Test Accuracy	98.17%
- Top-2 Accuracy	99.33%
- TFLite Model Size	2.35 MB
- Inference Time	~45 ms/frame
- Total Parameters	2,999,235
s
