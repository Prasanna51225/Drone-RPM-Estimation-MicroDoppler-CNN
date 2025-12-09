# 🛰️ Drone-RPM-Estimation-MicroDoppler-CNN (Defense Grade)

> 🎯 *A military-class radar intelligence system that decodes a drone’s propeller RPM from synthetic micro-Doppler radar signals — revealing payload, threat level, and intent.*  
> 💡 Powered by **5 GHz defense-grade FMCW radar simulation + signal intelligence + multi-scale CNN**  
> 🏆 **94.24% threat RPM classification accuracy — without flying a single drone in enemy airspace.**

🪖 *No test range permissions. No risk of drone loss. No battlefield data leaks.*  
⚔️ *Just physics, radar, and AI — built like a modern weapon for anti-UAV warfare.*

---

## 💥 Why RPM Matters in Military Drone Surveillance

In a battlefield, **a drone is not just a flying camera.**  
Its **RPM tells its mission.**

⚠️ *High RPM = heavy explosive payload or lethal delivery*  
⚠️ *Low RPM = long-duration reconnaissance / spying*  
⚠️ *Sudden RPM spikes = evasive maneuvers or last-second attack*  

🪖 Traditional systems only detect drones.  
They **don’t understand them.**

❌ Cannot estimate payload weight  
❌ Cannot estimate threat posture  
❌ Cannot detect attack acceleration  

🎖️ **This system reads drone intention before it strikes.**

> 🧠 *Anti-drone defense isn’t about seeing the drone. It’s about predicting what it’s about to do.*

---

# 🧠 Military-Grade System Architecture

```
┌────────────────┐
| Blender 3D UAV |
| (Hostile Drone)|
└──────┬─────────┘
       ↓
┌──────────────────────┐
| Synthetic FMCW Radar |
| (5 GHz battlefield)  |
└────────┬─────────────┘
         ↓
┌──────────────────────────┐
| Signal Intelligence Core |
| STFT | Matched Filtering |
| Range-Doppler | FFT      |
└──────────┬───────────────┘
           ↓
┌────────────────────────┐
| Feature Decomposition  |
| Magnitude | Phase | IF |
└───────────┬────────────┘
            ↓
┌──────────────────────────────┐
| Multi-Scale 1D CNN (Threat)  |
| L2 | GAP | Adaptive Dropouts |
└──────────────┬───────────────┘
               ↓
       🪖 **RPM → Payload → Threat**
```

⚔️ **Output:** Predicts behavior *before a drone can engage or drop payload.*

---

### 📌 1) 3D Hostile Drone Simulation  
*Target UAV rendered as threat model (can be quadcopter, octocopter, kamikaze UAV)*

<img width="581" height="363" alt="image" src="https://github.com/user-attachments/assets/45bc53e5-3b36-4886-b3fd-8136b7685ff0" />
<img width="463" height="362" alt="image" src="https://github.com/user-attachments/assets/5f4c85ae-ba8f-47af-bff7-ddb4e148a7f7" />

---

### 📌 2) Radar Spectrogram: Enemy UAV Movement Intelligence  
*(RPM signature reveals mission intent)*

| 💣 **700 RPM (Payload / Attack)** |  **400 RPM (Recon / Surveillance)** |
|-----------------------------------|----------------------------------------|
| (<img width="830" height="427" alt="image" src="https://github.com/user-attachments/assets/2f6fafa0-a0eb-49b1-8a53-48c5b510573f" />
) | (<img width="842" height="523" alt="image" src="https://github.com/user-attachments/assets/2f5344f8-ca50-4428-b9cf-834070c9cce0" />
) |

---

### 📌 3) Battle-Ready RPM Prediction (Real-Time Defense AI)

<img width="545" height="585" alt="image" src="https://github.com/user-attachments/assets/70abea0e-e753-4b24-b790-e5bbe18a7fe7" />

<img width="543" height="564" alt="image" src="https://github.com/user-attachments/assets/7eeef892-4c14-4e55-87bb-c99b30f2fcc2" />

---

## 📊 Combat-Proven Performance Metrics

| Metric | Value |
|--------|-------|
| **Threat RPM Accuracy** | 🥇 94.24% |
| **Battlefield Inference Speed** | ⚡ < 100 ms |
| **Real Radar Required** | ❌ None |
| **Cost of Training Data** | 💰 ₹0 |
| **Better Than Fourier** | +16% |
| **Better Than Wavelet** | +14.5% |

> 🪖 *Synthetic training = no risk of leaked battlefield intel.*

---

## 📂 Dataset (Built for War, Not for Lab Experiments)

🚁 **Threat RPM Classes**
```
Recon (100–300 RPM)
Tracking / Hostile Hover (400 RPM)
Heavy Payload / Attack (500–700 RPM)
```

🔐 Contains:
- Complex **military radar I/Q signals**
- **Magnitude, Phase, IF**
- **Spectrogram fingerprints**
- **Range-Doppler Intel**
- **Auto-generated threat truth labels**

💣 *No pilots. No drone crashes. No airspace permissions.*

---

## ⚙️ Defense-Grade Technology Stack

### 📡 Radar + Physics (Military Simulation)
- MATLAB – Phased Array/Radar Toolbox
- Battlefield FMCW Radar (5 GHz)
- Propeller Kinematics
- Micro-Doppler Threat Modeling

### 🔍 Signal Intelligence (SIGINT)
- STFT + Range-Doppler
- Matched Filtering
- Instantaneous Frequency Tracking

### 🧠 Defense AI (Anti-UAV)
- TensorFlow Multi-Scale 1D CNN
- Global Average Pooling
- L2 Regularization (anti-overfit)
- Adaptive Dropout Scheduling

### 💻 Tools of War
```bash
Python, MATLAB, Blender, TensorFlow,
NumPy, SciPy, Pandas, Matplotlib, SK-Learn
```

---

## 🧪 System Deployment (Zero Battlefield Risk)

### 🔧 Generate Synthetic War Data
```matlab
run_simulation.m
```

### 🎯 Train Threat Classifier
```bash
python train_rpm_cnn.py
```

### 🛡️ Deploy Real-Time Defense Model
```bash
python predict_rpm.py
```

---

## 🪖 Where This System Works

| Military Use Case | RPM Intelligence Helps |
|-------------------|------------------------|
| Border Surveillance | Identify spy drones |
| Base Protection | Detect bombing payload |
| Convoy Security | Spot ambush UAVs |
| Critical Infrastructure | Pre-attack detection |
| Anti-Smuggling Ops | Detect heavy carriers |
| Battlefield Recon | Track enemy scouts |

---

## 🏆 Why This Wins Military Hackathons

🔥 **It synthesizes its own war data.**  
⚔️ **It predicts enemy intent, not just presence.**  
🧠 **It’s physics + AI = weaponized intelligence.**  
🔒 **No classified footage. No RF recordings.**  
⚡ **Runs on laptops — deploy anywhere.**

💥 *Anti-drone warfare now fits in a backpack.*

---

## ⭐ Like This Project?

If you believe defense tech should be accessible and ethical, star ⭐ the repo.

> ⚔️ *Modern war is fought with intelligence before firepower.*  
> 🛰️ **We just armed AI with radar vision.**
