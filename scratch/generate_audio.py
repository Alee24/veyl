import math
import struct
import wave
import os

def create_futuristic_ringtone(filename):
    sample_rate = 44100
    duration = 4.0 # 4 seconds loop
    num_samples = int(sample_rate * duration)

    wave_file = wave.open(filename, 'w')
    wave_file.setnchannels(1) # mono
    wave_file.setsampwidth(2) # 16-bit
    wave_file.setframerate(sample_rate)

    # Sci-Fi Cyberpunk Arpeggio Ringtone Pattern
    # Frequencies: 523.25 (C5), 659.25 (E5), 783.99 (G5), 1046.50 (C6)
    freqs = [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
    
    for i in range(num_samples):
        t = i / sample_rate
        step = int((t % 0.8) / 0.1) # 8 steps per pulse burst
        
        # Sub-bass pulse + futuristic FM synthesis
        carrier_freq = freqs[step % len(freqs)]
        modulator_freq = carrier_freq * 2.0
        mod_index = 1.5 * math.sin(2 * math.pi * 5 * t)
        
        # Amplitude envelope for snappy attack/decay
        env = math.exp(-12 * ((t % 0.1)))
        
        # Generate FM synthesized wave
        val = math.sin(2 * math.pi * carrier_freq * t + mod_index * math.sin(2 * math.pi * modulator_freq * t))
        
        # Add high shimmer sine
        shimmer = 0.3 * math.sin(2 * math.pi * 3520 * t) * env
        
        sample = int((val * 0.7 + shimmer) * env * 24000)
        sample = max(-32768, min(32767, sample))
        wave_file.writeframes(struct.pack('<h', sample))

    wave_file.close()

def create_futuristic_outgoing(filename):
    sample_rate = 44100
    duration = 2.0 # 2 seconds radar ping
    num_samples = int(sample_rate * duration)

    wave_file = wave.open(filename, 'w')
    wave_file.setnchannels(1)
    wave_file.setsampwidth(2)
    wave_file.setframerate(sample_rate)

    for i in range(num_samples):
        t = i / sample_rate
        # Double radar ping every 1.5 seconds
        if t < 0.15 or (0.25 < t < 0.4):
            sub_t = t % 0.15
            env = math.sin(math.pi * sub_t / 0.15)
            freq = 987.77 # B5 high ping
            val = math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(2 * math.pi * freq * 1.5 * t)
            sample = int(val * env * 22000)
        else:
            sample = 0
        sample = max(-32768, min(32767, sample))
        wave_file.writeframes(struct.pack('<h', sample))

    wave_file.close()

def create_futuristic_notification(filename):
    sample_rate = 44100
    duration = 0.8
    num_samples = int(sample_rate * duration)

    wave_file = wave.open(filename, 'w')
    wave_file.setnchannels(1)
    wave_file.setsampwidth(2)
    wave_file.setframerate(sample_rate)

    for i in range(num_samples):
        t = i / sample_rate
        env = math.exp(-8 * t)
        freq = 1318.51 + 500 * t # Pitch slide up for futuristic feel
        val = math.sin(2 * math.pi * freq * t) + 0.4 * math.sin(2 * math.pi * freq * 2.0 * t)
        sample = int(val * env * 25000)
        sample = max(-32768, min(32767, sample))
        wave_file.writeframes(struct.pack('<h', sample))

    wave_file.close()

os.makedirs('frontend/assets/audio', exist_ok=True)
create_futuristic_ringtone('frontend/assets/audio/futuristic_ringtone.wav')
create_futuristic_outgoing('frontend/assets/audio/futuristic_outgoing.wav')
create_futuristic_notification('frontend/assets/audio/futuristic_notification.wav')
print("Successfully generated futuristic audio assets!")
