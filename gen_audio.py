# pip install pandas gtts

import pandas as pd
from gtts import gTTS
import os

# Load CSV
df = pd.read_csv("stimuli_es/stimuli_es.csv")  # should have a column "sentence"

# Make output directory
os.makedirs("audio", exist_ok=True)

# Loop through sentences
for i, text in enumerate(df["question_SPAN"]):
    # Generate Spanish TTS
    tts = gTTS(text=text, lang="es")
    filename = f"audio/sentence_{i}.wav"
    tts.save(filename)
    
    # Add filename to dataframe
    df.loc[i, "audio_file"] = filename

# Save updated CSV
df.to_csv("sentences_with_audio.csv", index=False)