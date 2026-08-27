import os
import time
import json
import sqlite3
import io
import wave
import bcrypt

from fastapi import FastAPI, UploadFile, File, WebSocket, WebSocketDisconnect, Form, Query, Depends, HTTPException, status
from fastapi.responses import Response, FileResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from google import genai
from google.genai import types
from pydantic import BaseModel, Field, EmailStr
from docx2pdf import convert
from docx import Document
from fpdf import FPDF

# Database imports
from sqlalchemy.orm import Session
import models
from database import engine, get_db

# 1. Create DB tables automatically on startup
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SLT 1.0 Speech-to-Text API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = genai.Client(api_key="YOUR_API_KEY_HERE")

# --- 2. Initialize SQLite Database for Transcripts ---
conn = sqlite3.connect("transcripts.db", check_same_thread=False)
cursor = conn.cursor()
cursor.execute("""
    CREATE TABLE IF NOT EXISTS transcript_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        transcript_data TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
""")
conn.commit()
# ----------------------------------------------------

# --- Pydantic Schemas ---
class RegisterSchema(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    mobile: str
    password: str

class TranscriptSegment(BaseModel):
    speaker: str = Field(description="The identified speaker")
    text: str = Field(description="The transcribed and grammar-corrected text")
    language: str = Field(description="The primary language of this segment")

class MeetingTranscript(BaseModel):
    title: str = Field(description="A short, generated title for the conversation")
    segments: list[TranscriptSegment]


# Helper to hash passwords using direct bcrypt (truncating to safe 72-byte limit)
def hash_password(password: str) -> str:
    pwd_bytes = password.encode('utf-8')[:72]
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(pwd_bytes, salt).decode('utf-8')


# --- Authentication Endpoints ---
@app.post("/auth/register", status_code=status.HTTP_201_CREATED)
async def register_user(user_data: RegisterSchema, db: Session = Depends(get_db)):
    # 1. Check if user already exists
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already registered"
        )

    # 2. Hash password & Save to Database
    hashed_pwd = hash_password(user_data.password)
    new_user = models.User(
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        email=user_data.email,
        mobile=user_data.mobile,
        hashed_password=hashed_pwd
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {
        "status": "success",
        "message": "User registered successfully",
        "data": {"id": new_user.id, "email": new_user.email}
    }


def get_prompt_for_mode(mode: str) -> str:
    if mode.startswith("English"):
        return """
        Analyze this audio file and provide a highly accurate transcription.
        1. Transcribe the entire speech using ONLY the English/Latin alphabet.
        2. If Sinhala words are spoken, transliterate them into English letters.
        3. Identify different speakers.
        4. Apply proper punctuation and correct any basic grammatical errors.
        CRITICAL: DO NOT output any Sinhala script letters in the text field. Use only English letters.
        """
    elif mode.startswith("Sinhala"):
        return """
        Analyze this audio file and provide a highly accurate transcription.
        1. Transcribe the entire speech using ONLY Sinhala script.
        2. If English words are spoken, transliterate them into Sinhala script.
        3. Identify different speakers.
        4. Apply proper punctuation and correct any basic grammatical errors.
        CRITICAL: DO NOT output any English/Latin letters in the text field. Use only Sinhala script.
        """
    else:  # Hybrid / Singlish
        return """
        Analyze this audio file and provide a highly accurate transcription.
        1. For English words spoken, write them in English.
        2. For Sinhala words spoken, write them in Sinhala script.
        3. Identify different speakers.
        4. Apply proper punctuation and correct any basic grammatical errors.
        """

@app.post("/transcribe")
async def transcribe_endpoint(
    audio_file: UploadFile = File(...),
    language_mode: str = Form("English")
):
    print(f"Receiving file: {audio_file.filename}")
    
    temp_file_path = f"temp_{audio_file.filename}"
    with open(temp_file_path, "wb") as f:
        f.write(await audio_file.read())
        
    print("Uploading to Gemini...")
    gemini_file = client.files.upload(file=temp_file_path)
    
    while gemini_file.state.name == "PROCESSING":
        print("Processing audio on cloud...")
        time.sleep(2)
        gemini_file = client.files.get(name=gemini_file.name)

    prompt = get_prompt_for_mode(language_mode)

    response = client.models.generate_content(
        model="gemini-2.5-flash", 
        contents=[prompt, gemini_file],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=MeetingTranscript,
            temperature=0.0,
        )
    )
    
    os.remove(temp_file_path)
    
    # Save the JSON to the Database
    transcript_json = response.text
    parsed_json = json.loads(transcript_json)
    
    cursor.execute(
        "INSERT INTO transcript_history (title, transcript_data) VALUES (?, ?)", 
        (parsed_json.get("title", "Untitled"), transcript_json)
    )
    conn.commit()
    print("Saved to database successfully.")
    
    return parsed_json

@app.get("/history")
def get_history():
    cursor.execute("SELECT id, title, created_at, transcript_data FROM transcript_history ORDER BY created_at DESC")
    records = cursor.fetchall()
    
    history = []
    for row in records:
        history.append({
            "id": row[0],
            "title": row[1],
            "created_at": row[2],
            "transcript_data": json.loads(row[3])
        })
    return {"history": history}

@app.get("/history/search")
def search_history(query: str):
    search_term = f"%{query}%"
    cursor.execute(
        "SELECT id, title, created_at, transcript_data FROM transcript_history WHERE transcript_data LIKE ? ORDER BY created_at DESC", 
        (search_term,)
    )
    records = cursor.fetchall()
    
    results = []
    for row in records:
        results.append({
            "id": row[0],
            "title": row[1],
            "created_at": row[2],
            "transcript_data": json.loads(row[3])
        })
    return {"results": results}

@app.get("/export/txt/{transcript_id}")
def export_txt(transcript_id: int):
    cursor.execute("SELECT title, transcript_data FROM transcript_history WHERE id = ?", (transcript_id,))
    row = cursor.fetchone()
    if not row:
        return {"error": "Transcript not found"}

    title, data_str = row[0], row[1]
    data = json.loads(data_str)

    text_content = f"Title: {title}\n"
    text_content += "=" * 40 + "\n\n"
    for segment in data.get("segments", []):
        text_content += f"[{segment['speaker']}] ({segment['language']}): {segment['text']}\n\n"

    filename = f"{title.replace(' ', '_')}.txt"
    return Response(
        content=text_content,
        media_type="text/plain",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@app.get("/export/docx/{transcript_id}")
def export_docx(transcript_id: int):
    cursor.execute("SELECT title, transcript_data FROM transcript_history WHERE id = ?", (transcript_id,))
    row = cursor.fetchone()
    if not row:
        return {"error": "Transcript not found"}

    title, data_str = row[0], row[1]
    data = json.loads(data_str)

    doc = Document()
    doc.add_heading(title, level=1)

    for segment in data.get("segments", []):
        p = doc.add_paragraph()
        p.add_run(f"{segment['speaker']} ({segment['language']}): ").bold = True
        p.add_run(segment['text'])

    file_stream = io.BytesIO()
    doc.save(file_stream)
    file_stream.seek(0)

    filename = f"{title.replace(' ', '_')}.docx"
    return Response(
        content=file_stream.getvalue(),
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@app.get("/export/pdf/{transcript_id}")
def export_pdf(transcript_id: int):
    cursor.execute("SELECT title, transcript_data FROM transcript_history WHERE id = ?", (transcript_id,))
    row = cursor.fetchone()
    if not row:
        return {"error": "Transcript not found"}

    title, data_str = row[0], row[1]
    data = json.loads(data_str)

    pdf = FPDF()
    pdf.add_page()
    
    pdf.add_font("NotoSansSinhala", "", "NotoSansSinhala-Regular.ttf", uni=True)
    pdf.set_font("NotoSansSinhala", size=16)
    
    pdf.cell(200, 10, txt=title, ln=True, align='C')
    pdf.ln(10)

    pdf.set_font("NotoSansSinhala", size=12)
    for segment in data.get("segments", []):
        speaker_info = f"[{segment['speaker']}] ({segment['language']}): "
        text = segment['text']
        
        pdf.multi_cell(0, 10, txt=speaker_info + text)
        pdf.ln(2)

    pdf_output = pdf.output(dest='S').encode('latin1')

    filename = f"{title.replace(' ', '_')}.pdf"
    return Response(
        content=pdf_output,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@app.websocket("/stream")
async def live_transcription(websocket: WebSocket, language_mode: str = Query("English")):
    await websocket.accept()
    print("Mobile app connected to live stream!")
    
    try:
        while True:
            audio_file_bytes = await websocket.receive_bytes()
            print("Received audio block. Sending directly to Gemini...")
            
            try:
                wav_io = io.BytesIO()
                with wave.open(wav_io, 'wb') as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2)
                    wav_file.setframerate(16000)
                    wav_file.writeframes(audio_file_bytes)
                
                wav_data = wav_io.getvalue()
                live_prompt = get_prompt_for_mode(language_mode)
                
                response = client.models.generate_content(
                    model="gemini-2.5-flash", 
                    contents=[
                        live_prompt,
                        types.Part.from_bytes(
                            data=wav_data,
                            mime_type="audio/wav"
                        )
                    ],
                    config=types.GenerateContentConfig(
                        temperature=0.0,
                    )
                )
                
                if response.text:
                    print(f"Success! Translated: {response.text.strip()}")
                    await websocket.send_json({
                        "status": "success",
                        "text": response.text.strip(),
                        "language": "Live AI"
                    })
                
            except Exception as e:
                print(f"Live processing error: {e}")
                try:
                    await websocket.send_json({
                        "status": "error",
                        "text": f"Backend Error: {str(e)}",
                        "language": "System"
                    })
                except:
                    pass
                
    except WebSocketDisconnect:
        print("Mobile app disconnected. Live recording stopped.")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)