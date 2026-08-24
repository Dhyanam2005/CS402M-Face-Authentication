# CS402M — Synthetic Face Dataset (Class A / Class B)

## Overview
This repository contains a synthetic image dataset built from single reference
photographs using a diffusion-based image-to-image generative model, expanded
with conventional augmentation, and split into train/val/test sets.

- **Class A**: two sub-identities (A1, A2), merged into one class folder
- **Class B**: one identity
- Minimum 500 images per class, split 80/10/10 (train/val/test)

## Input images
| Class | Sub-identity | Source file |
|---|---|---|
| A | A1 | `teammate1.jpg` |
| A | A2 | `teammate2.jpg` |
| B | — | `Sir.jpg` |

## Generative model
- **Model**: Stable Diffusion v1.5 (`stable-diffusion-v1-5/stable-diffusion-v1-5` on Hugging Face Hub)
- **Pipeline**: `StableDiffusionImg2ImgPipeline` (diffusers library)
- **Task**: image-to-image synthesis conditioned on a single reference photo per identity

### Hyperparameters
| Parameter | Value |
|---|---|
| `strength` | 0.20 |
| `guidance_scale` | 7.0 |
| `num_inference_steps` | 30 |
| Image size | 512 x 512 |
| Seed | randomized per image, logged in metadata |
| `negative_prompt` | different person, another person, multiple people, deformed face, distorted face, malformed eyes, malformed mouth, extra face, duplicate person, asymmetrical face, blurry face, cartoon, illustration, painting, unrealistic skin, extreme pose, extreme aging, low quality |

### Prompt construction
Each generated image uses a randomly sampled combination of:
- age appearance (6 options)
- build (4 options)
- framing/scale (4 options)
- lighting condition (8 options)
- pose offset (6 options)
- background (7 options)
- expression (6 options)
- camera style (6 options)
- clothing (5 options)

drawn from 3 alternate prompt templates, to avoid near-duplicate prompts across
the 500 generations per identity.

## Conventional augmentation pipeline
Used to top up each class to the 500-image minimum and add pixel-level
(non-generative) variation on top of the diffusion outputs.

| Augmentation | Probability | Parameters |
|---|---|---|
| Horizontal flip | 0.5 | — |
| Brightness jitter | 0.7 | factor in [0.85, 1.15] |
| Rotation | 1.0 (applied whenever augmentation triggers) | +/-15 degrees |
| Gaussian noise | 0.5 | std = 12 (pixel units, 0-255 scale) |

Each augmented image's exact transform combination is logged per-image in
`metadata.csv` inside its split folder (e.g. `dataset/train/A/metadata.csv`).

## Dataset structure
```
dataset/
├── train/
│   ├── A/
│   │   ├── A_train_0001.png
│   │   ├── ...
│   │   └── metadata.csv
│   └── B/
│       ├── B_train_0001.png
│       ├── ...
│       └── metadata.csv
├── val/
│   ├── A/...
│   └── B/...
└── test/
    ├── A/...
    └── B/...
```

Split ratio: **80% train / 10% val / 10% test**, computed independently per class.
