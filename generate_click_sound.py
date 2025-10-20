"""
Script to generate metronome click sounds using numpy and scipy.
Run this to create click.wav and click_accent.wav files.

Requirements:
pip install numpy scipy
"""

import numpy as np
from scipy.io import wavfile

def generate_click(filename, frequency=1000, duration=0.05, sample_rate=44100):
    """
    Generate a short click sound
    
    Args:
        filename: Output WAV filename
        frequency: Frequency of the click in Hz (higher = sharper)
        duration: Duration in seconds
        sample_rate: Sample rate in Hz
    """
    # Generate time array
    t = np.linspace(0, duration, int(sample_rate * duration))
    
    # Generate sine wave
    audio = np.sin(2 * np.pi * frequency * t)
    
    # Apply envelope to make it click-like (exponential decay)
    envelope = np.exp(-10 * t / duration)
    audio = audio * envelope
    
    # Normalize to 16-bit range
    audio = np.int16(audio * 32767 * 0.8)  # 0.8 to prevent clipping
    
    # Write to file
    wavfile.write(filename, sample_rate, audio)
    print(f"Generated {filename}")

# Generate normal click (1000 Hz)
generate_click('mobile_app/assets/audio/click.wav', frequency=1000, duration=0.05)

# Generate accent click (1200 Hz, slightly longer)
generate_click('mobile_app/assets/audio/click_accent.wav', frequency=1200, duration=0.08)

print("\nClick sounds generated successfully!")
print("Files created:")
print("  - mobile_app/assets/audio/click.wav")
print("  - mobile_app/assets/audio/click_accent.wav")
