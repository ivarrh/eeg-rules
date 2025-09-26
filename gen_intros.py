# pip install pandas gtts
import pandas as pd
from gtts import gTTS
import os

# Load CSV
df = pd.read_csv("stimuli_es/stimuli_es.csv")  # should have a column "sentence"

intros = df[["scene", "origin_SPAN", "rule_SPAN"]].drop_duplicates().reset_index(drop=True)

# Make output directory
os.makedirs("audio/intros", exist_ok=True)

# Loop through sentences
for i, row in intros.iterrows() :
    
    text = row["origin_SPAN"]
    
    # Generate Spanish TTS
    tts = gTTS(text=text, lang="es")
    
    # Create filename from CSV values
    scenario   = row["scene"]
    filename = f"audio/{scenario}_origin.wav"
    
    tts.save(filename)
    
    text = row["rule_SPAN"]
    
    # Generate Spanish TTS
    tts = gTTS(text=text, lang="es")
    
    # Create filename from CSV values
    scenario   = row["scene"]
    filename = f"audio/{scenario}_rule.wav"
    
    tts.save(filename)
    
    # Add filename to dataframe
    #df.loc[i, "audio_file"] = filename

# Save updated CSV
#df.to_csv("stimuli_es_with_audio.csv", index=False)