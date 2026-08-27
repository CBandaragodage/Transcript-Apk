import time
from google import genai
from google.genai import types
from pydantic import BaseModel, Field

# 1. Define the exact JSON structure we want back
class TranscriptSegment(BaseModel):
    speaker: str = Field(description="The identified speaker, e.g., Speaker A, Speaker B")
    text: str = Field(description="The transcribed and grammar-corrected text")
    language: str = Field(description="The primary language of this segment: Sinhala, English, or Singlish")

class MeetingTranscript(BaseModel):
    title: str = Field(description="A short, generated title for the conversation")
    segments: list[TranscriptSegment]


client = genai.Client(api_key="YOUR_API_KEY_HERE")

def transcribe_audio(file_path):
    print(f"Uploading {file_path} to Gemini...")
    
    # 3. Upload the audio file
    audio_file = client.files.upload(file=file_path)
    
    while audio_file.state.name == "PROCESSING":
        print("Processing audio...")
        time.sleep(2)
        audio_file = client.files.get(name=audio_file.name)
        
    print("Upload complete. Starting transcription...")

    prompt = """
    Analyze this audio file and provide a highly accurate transcription.
    1. Detect and accurately transcribe mixed Sinhala and English (Singlish) conversations.
    2. Identify different speakers.
    3. Apply proper punctuation and correct any basic grammatical errors.
    """

    # 4. Call the Flash model and force it to use our JSON schema
    response = client.models.generate_content(
        model="gemini-3.5-flash", 
        contents=[prompt, audio_file],
        config=types.GenerateContentConfig(
            response_mime_type="application/json",
            response_schema=MeetingTranscript,
        )
    )

    # 5. Output the structured JSON result
    print("\n--- STRUCTURED JSON RESULT ---")
    print(response.text)

if __name__ == "__main__":
    # Ensure your test file name is correct here
    transcribe_audio("a.mp3")
