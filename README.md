# Quad telemetry dashboard

Advanced lua-based dashboard for the OpenTX (EdgeTX) Monochrome LCD Transmitters

![opentx-quad-telemetry](https://i.postimg.cc/vZGKJ7rC/opentx-quad-telemetry.gif)

## Features

* Transmitter battery + Model name + Time
* Battery voltage (graphical and numerical)
* RX signal strength (graphical and icon)
* Flight Timer *(perfect for whooping)*
* ANIMATED QUAD WHEN ARMED !

### Additional

- Crossfire & ExpressLRS telemetry support
- Works with bigger screens *(Tango2, X9D)*
- Shows avarage battery cells voltage
- Displays GPS positioning

## Author

* Original script by Andrew Farley - farley@neonsurge(dot)com
* Git: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard

## Installing

1. Download the `quad.lua` script above **(code -> download zip)**.
1. Open `quad.lua` in notepad and edit **settings** section for you choice.
1. Place this script into your `/SCRIPTS/TELEMETRY` folder on the radio.

#### Bootloader Method

1. Power off your transmitter and power it back on in bootloader mode.
1. Connect a USB cable and open the SD card drive on your computer.
1. Put the script file to appropriate folder.
1. Unplug the USB cable and power cycle your transmitter.

#### Manual method

1. Power off your transmitter.
1. Remove the SD card and plug it into a computer
1. Put the script file to appropriate folder.
1. Reinsert your SD card into the transmitter.
1. Power up your transmitter.

If you copied the files correctly, you can now follow next step and **set up the script as telemetry page**.

## Setting telemetry page

These instructions are for the **X9 Lite**, so please be aware the steps may vary slightly for your device.

1. Hit the <kbd>MENU</kbd> button and select the model for which you would like to enable the script.
1. While on the `MODEL SEL` screen, long-press the <kbd>PAGE</kbd> button to navigate to the `DISPLAY` page.
1. Move the cursor to a free screen and hit <kbd>ENTER</kbd>.
1. Scroll and select the `Script` option and press <kbd>ENTER</kbd>.
1. Move the cursor to the script selection field `---` and hit <kbd>ENTER</kbd>.
1. Select one of the listed telemetry scripts and press <kbd>ENTER</kbd>.
1. Long-press <kbd>EXIT</kbd> to return to your model screen.

## Usage

To **invoke the script**, simply long-press the <kbd>PAGE</kbd> button or shortly press <kbd>TELE</kbd> from the **model screen**.

Shortly press <kbd>EXIT</kbd> or <kbd>RTN</kbd> to display **Transmitter output** info *(for crossfire)* and **GPS positioning** section *(if telemetry source exists)*.