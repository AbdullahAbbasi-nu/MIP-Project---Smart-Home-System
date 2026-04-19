**🚀 ATmega32 MIP Project: Smart Home Automation System**

**👥 The Team**

Abdullah Abbasi - Project Lead / Firmware

Ghulam Abbas - Hardware Design / Simulation

**📂 Repository Structure**
src/ - Assembly source code (.asm).

simulation/ - Proteus design files.

bin/ - Compiled .hex files for the ATmega32 and Flame sensor.

hardware/ - Real-world circuit photos and schematics.

**🛠️ Simulation Instructions**
To run this project, you will need Proteus Design Suite (Version 8.0 or higher recommended).

1. Opening the Project
Navigate to the simulation/ folder.

Open the file named MIP Project.pdsprj.

Note: If you are using an older version of Proteus, look for the .DSN file.

2. Uploading the HEX File to ATmega32
The simulation won't work unless the ATmega32 "knows" what code to run. Follow these steps:

Right-click on the ATmega32 microcontroller in the Proteus workspace.

Select Edit Properties (or simply double-click the chip).

Look for the Program File field.

Click the Folder Icon 📁 on the right of that field.

Navigate to the bin/ folder in this repository and select main.hex.

Important: Ensure the "Clock Frequency" in the properties matches your code (usually 8MHz or 16MHz).

Click OK.

3. Uploading the Flame Sensor HEX
If your simulation uses a Flame Sensor module that requires its own firmware:

Double-click the Flame Sensor component.

In the Program File field, browse and select flame.hex from the bin/ folder.

Click OK.

4. Running the Simulation
Press the Play (▷) button at the bottom-left corner of the Proteus window.

Observe the [LCD/LEDs/Motors] to verify the logic.

**📸 Hardware Implementation**
Check the hardware/ folder for images of our physical circuit. We used a [USBasp/AVR ISP MkII] programmer to flash the main.hex onto the physical ATmega32 chip.

**⚠️ Troubleshooting**
Simulation Running Slow? Check if your computer is under heavy load; Proteus is CPU-intensive.

Logic Errors? Ensure the CKSEL fuses in Proteus are set to "Internal RC" or "External Crystal" depending on your project requirements.

Missing Files? If a component shows a "Library not found" error, ensure you have the necessary Proteus libraries installed for the Flame sensor.
