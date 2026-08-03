import os
import time
import json
import sqlite3 
from fastapi import FastAPI, UploadFile, File
import uvicorn
from google import genai
from google.genai import types
from pydantic import BaseModel, Field
from docx2pdf import convert
from fastapi.responses import Response, FileResponse
from docx import Document
from fpdf import FPDF
import io
import wave
from google.genai import types
from fastapi import FastAPI, UploadFile, File, WebSocket, WebSocketDisconnect, Form, Query

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="SLT 1.0 Speech-to-Text API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

client = genai.Client(api_key="YOUR_API_KEY_HERE")

# --- 2. Initialize SQLite Database ---
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
# -------------------------------------

class TranscriptSegment(BaseModel):
    speaker: str = Field(description="The identified speaker")
    text: str = Field(description="The transcribed and grammar-corrected text")
    language: str = Field(description="The primary language of this segment")

class MeetingTranscript(BaseModel):
    title: str = Field(description="A short, generated title for the conversation")
    segments: list[TranscriptSegment]

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
    else: # Hybrid / Singlish
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
    
    # --- 3. Save the JSON to the Database ---
    transcript_json = response.text
    parsed_json = json.loads(transcript_json)
    
    cursor.execute(
        "INSERT INTO transcript_history (title, transcript_data) VALUES (?, ?)", 
        (parsed_json.get("title", "Untitled"), transcript_json)
    )
    conn.commit()
    print("Saved to database successfully.")
    # ----------------------------------------
    
    return parsed_json

@app.get("/history")
def get_history():
    # Fetch all saved transcripts, ordered by the newest first
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
    # Search the database for any transcript containing the query word
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

# 1. Export as Plain Text (.txt)
@app.get("/export/txt/{transcript_id}")
def export_txt(transcript_id: int):
    cursor.execute("SELECT title, transcript_data FROM transcript_history WHERE id = ?", (transcript_id,))
    row = cursor.fetchone()
    if not row:
        return {"error": "Transcript not found"}

    title, data_str = row[0], row[1]
    data = json.loads(data_str)

    # Build plain text content
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


# 2. Export as Word Document (.docx)
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

    # Save document into memory stream
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
    
    # Use the local Sinhala font to support both Sinhala and English text
    pdf.add_font("NotoSansSinhala", "", "NotoSansSinhala-Regular.ttf", uni=True)
    pdf.set_font("NotoSansSinhala", size=16)
    
    # Title
    pdf.cell(200, 10, txt=title, ln=True, align='C')
    pdf.ln(10)

    pdf.set_font("NotoSansSinhala", size=12)
    for segment in data.get("segments", []):
        speaker_info = f"[{segment['speaker']}] ({segment['language']}): "
        text = segment['text']
        
        pdf.multi_cell(0, 10, txt=speaker_info + text)
        pdf.ln(2)

    # Save to a byte string
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
            # 1. Receive the 3-second WEBM audio bytes from the browser
            audio_file_bytes = await websocket.receive_bytes()
            print("Received audio block. Sending directly to Gemini...")
            
            try:
                # 2. Add WAV header to the raw PCM data sent by Flutter
                wav_io = io.BytesIO()
                with wave.open(wav_io, 'wb') as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2) # 16-bit
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
                
                # 3. Send the real AI text back to the screen
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