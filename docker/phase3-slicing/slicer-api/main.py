"""
Slicer API — thin FastAPI wrapper around headless PrusaSlicer.

Accepts STL/3MF uploads + a printer profile name, runs PrusaSlicer CLI,
and returns the resulting G-code file.
"""

import os
import subprocess
import tempfile
import uuid
from pathlib import Path

from fastapi import FastAPI, File, Header, HTTPException, Query, UploadFile
from fastapi.responses import FileResponse

app = FastAPI(title="Printarr Slicer API", version="0.1.0")

PRUSASLICER_BIN = os.environ.get("PRUSASLICER_BIN", "/usr/bin/prusa-slicer")
PROFILES_DIR = Path(os.environ.get("PROFILES_DIR", "/configs"))
INPUT_DIR = Path(os.environ.get("INPUT_DIR", "/input"))
OUTPUT_DIR = Path(os.environ.get("OUTPUT_DIR", "/output"))
API_KEY = os.environ.get("API_KEY", "")

ALLOWED_SUFFIXES = {".stl", ".3mf", ".obj", ".amf"}


def _check_api_key(x_api_key: str | None) -> None:
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing API key")


@app.get("/healthz")
async def healthz() -> dict:
    return {"status": "ok"}


@app.get("/profiles")
async def list_profiles(x_api_key: str | None = Header(default=None)) -> dict:
    """Return available printer profiles."""
    _check_api_key(x_api_key)
    profiles = [p.stem for p in PROFILES_DIR.glob("*.ini")]
    return {"profiles": sorted(profiles)}


@app.post("/slice")
async def slice_model(
    file: UploadFile = File(...),
    profile: str = Query(..., description="Printer profile name (without .ini)"),
    x_api_key: str | None = Header(default=None),
) -> FileResponse:
    """
    Upload a model file and slice it with the specified profile.
    Returns the G-code file as a download.
    """
    _check_api_key(x_api_key)

    suffix = Path(file.filename or "model.stl").suffix.lower()
    if suffix not in ALLOWED_SUFFIXES:
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {suffix}")

    profile_path = PROFILES_DIR / f"{profile}.ini"
    if not profile_path.exists():
        raise HTTPException(status_code=404, detail=f"Profile not found: {profile}")

    job_id = uuid.uuid4().hex
    input_path = INPUT_DIR / f"{job_id}{suffix}"
    output_path = OUTPUT_DIR / f"{job_id}.gcode"

    INPUT_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    input_path.write_bytes(await file.read())

    cmd = [
        PRUSASLICER_BIN,
        "--load", str(profile_path),
        "--export-gcode",
        "--output", str(output_path),
        str(input_path),
    ]

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=300
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="Slicing timed out after 300s")
    finally:
        input_path.unlink(missing_ok=True)

    if result.returncode != 0:
        raise HTTPException(
            status_code=500,
            detail=f"PrusaSlicer exited {result.returncode}: {result.stderr[:500]}",
        )

    if not output_path.exists():
        raise HTTPException(status_code=500, detail="G-code file not produced")

    original_stem = Path(file.filename or "model").stem
    return FileResponse(
        path=str(output_path),
        media_type="text/plain",
        filename=f"{original_stem}_{profile}.gcode",
        background=None,
    )
