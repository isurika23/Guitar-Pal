
# 🎸 GuitarPal – Smart Guitar Learning Assistant

**GuitarPal** is an embedded system designed to assist beginners in learning the guitar more effectively and interactively. By placing addressable LEDs under each string at every fret and using touch sensors to detect finger placement, this system provides real-time visual guidance and feedback through a connected mobile app.

## 🚀 Project Goal

To create a low-cost, extendable guitar learning tool that:
- Guides users with LED-lit note/chord positions
- Detects and verifies correct finger placement
- Provides real-time feedback via a mobile application
- Makes practice intuitive and motivating for beginners

## 🔧 Key Features (MVP)
- Individually addressable LED strips for visual fret guidance
- Capacitive/resistive touch sensors to detect correct finger positions (detecting method is TBD)
- Bluetooth communication with a custom mobile app
- Real-time accuracy feedback through the app

## 🧩 Tech Stack

### 📱 Mobile App (Flutter)

### ⚙️ Embedded System
- **Microcontroller:** ESP32 (Wi-Fi/Bluetooth, GPIO support)
- **Sensors:** (TBD)
- **Visuals:** WS2812B addressable RGB LED strips

## 🗓️ Project Timeline (Feasibility Plan)

| Week(s) | Milestone                                                                 |
|---------|---------------------------------------------------------------------------|
| **Week 1–2** | 🔧 Research & Requirements Finalization <br>• Literature review <br>• Component sourcing (ESP32, LEDs, sensors) <br>• Confirm fretboard layout and hardware design |
| **Week 3–4** | 💡 Hardware Prototyping <br>• LED control with ESP32 <br>• Basic touch sensor testing <br>• Breadboard layout & power setup |
| **Week 5–6** | 🔌 Bluetooth Communication <br>• Set up BLE with ESP32 <br>• Mobile app connects to hardware <br>• Test sending commands from app to light LEDs |
| **Week 7–8** | 📱 Mobile App Core Features <br>• Flutter UI for chord/note selection <br>• Integrate with BLE logic <br>• Touch sensor feedback shown on app |
| **Week 9–10** | 🧪 Integration & Testing <br>• Full system testing (LED + touch + app) <br>• Debug interaction delays & UI bugs <br>• Fine-tune fretboard response |
| **Week 11–12** | ✅ Finalization & Polish <br>• Refactor code & optimize power usage <br>• Document system and app <br>• Prepare for presentation/demo <br>• Buffer time for unexpected issues |

### ⏱️ Time Commitment
- **Total Estimated Weekly Commitment:** ~8–10 hrs (flexible)

## 📚 License
MIT License

<h3>🎸 System Preview (Reference Image)</h3>

<p>Below is a reference image of a market product similar to what GuitarPal aims to achieve. This helps visualize how LEDs might be integrated along the fretboard for learning and guidance purposes.</p>

<img src="https://knowtechie.com/wp-content/uploads/2019/06/4-crowdfunding-products-fret-zealot-guitar-teaching-device.jpg" alt="Reference Product" width="400"/>

*Image used for illustrative purposes only. All rights belong to the original manufacturer or creator.*

---

> _This is a research-fhttps://knowtechie.com/wp-content/uploads/2019/06/4-crowdfunding-products-fret-zealot-guitar-teaching-device.jpgocused prototype aimed at improving beginner engagement and accuracy in guitar practice. Contributions, feedback, and collaboration are welcome!_