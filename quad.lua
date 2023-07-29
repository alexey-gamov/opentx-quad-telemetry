----------------------------------------------------------------------
-- Original script by Andrew Farley - farley@neonsurge(dot)com
-- Git: https://github.com/AndrewFarley/Taranis-XLite-Q7-Lua-Dashboard
--
-- Optimization and modding by Alexey Gamov - dev@alexey-gamov(dot)ru
-- Git: https://github.com/alexey-gamov/opentx-quad-telemetry
----------------------------------------------------------------------

-- Tune this section before using script (no need for crossfire users)
-- Targets for 3pos switch: 0-50-100. Battery option: VFAS, Cels, RxBt 

local settings = {
	arm = {switch = 'sd', target = 100},
	mode = {switch = 'sb', list = {'Acro', 'Angle', 'Horizon'}},
	battery = {voltage = 'VFAS', used = 'Fuel'},
	telemetry = {satcount = 'Sats', timer = 1}
}

------- DRAW FUNCTIONS -------

-- Sexy tx voltage icon with % indication
local function drawTransmitterVoltage(x, y, w)
	local percent = math.min(math.max(math.ceil((txvoltage - radio.battMin) * 100 / (radio.battMax - radio.battMin)), 0), 100)
	local filling = math.ceil(percent / 100 * (w - 1) + 0.2)

	-- Battery outline
	lcd.drawRectangle(x, y, w + 1, 6, SOLID)
	lcd.drawLine(x + w + 1, y + 1, x + w + 1, y + 4, SOLID, FORCE)

	-- Battery percentage (after battery)
	lcd.drawText(x + w + 4, y, percent .. '%', SMLSIZE + (percent > 20 and 0 or BLINK))

	-- Fill the battery
	lcd.drawRectangle(x, y + 1, filling, 4, SOLID)
	lcd.drawRectangle(x, y + 2, filling, 2, SOLID)
end

-- Current time with icon
local function drawTime(x, y)
	local timeNow = getDateTime()

	-- Clock icon
	lcd.drawLine(x + 1, y + 0, x + 4, y + 0, SOLID, FORCE)
	lcd.drawLine(x + 0, y + 1, x + 0, y + 4, SOLID, FORCE)
	lcd.drawLine(x + 5, y + 1, x + 5, y + 4, SOLID, FORCE)
	lcd.drawLine(x + 2, y + 2, x + 2, y + 3, SOLID, FORCE)
	lcd.drawLine(x + 2, y + 3, x + 3, y + 3, SOLID, FORCE)
	lcd.drawLine(x + 1, y + 5, x + 4, y + 5, SOLID, FORCE)

	-- Time as text, blink on tick
	lcd.drawText(x + 08, y, string.format('%02.0f%s', timeNow.hour, math.ceil(tick) == 1 and '' or ':'), SMLSIZE)
	lcd.drawText(x + 20, y, string.format('%02.0f', timeNow.min), SMLSIZE)
end

-- Big and sexy battery graphic with average cell voltage
local function drawVoltageImage(x, y, w, h, s)
	local batt, cell, battMin = 0, 0, 3.3

	-- Try to calculate cells count from batt voltage or skip if using Cels telemetry
	-- Don't support 5s and 7s: it's dangerous to detect - empty 8s look like an 7s!
	if (type(voltage) == 'table') then
		for i, v in ipairs(voltage) do
			batt = batt + v
			cell = cell + 1
		end

		voltage = batt
	else
		cell = math.ceil(voltage / 4.37)
		cell = cell == (5 or 7) and cell + 1 or cell

		batt = voltage
	end

	-- Store max voltage per cell until batt is changed, also detect HV type
	battMax = math.max(link ~= 0 and battMax or 0, batt > 4.22 * cell and 4.35 or 4.2)

	-- Calculate increment and starting point
	s = s or math.floor(h / 18) * 2
	y = (h - s * 8) / 2 + 8

	-- Draw battery outline
	lcd.drawLine(x + 2, y - 1, x + w - 2, y - 1, SOLID, 0)
	lcd.drawLine(x, y, x + w - 1, y, SOLID, 0)
	lcd.drawLine(x, y, x, y + s * 8, SOLID, 0)
	lcd.drawLine(x, y + s * 8, x + w - 1, y + s * 8, SOLID, 0)
	lcd.drawLine(x + w, y + 1, x + w, y + s * 8 - 1, SOLID, 0)

	-- Draw battery markers from top to bottom
	lcd.drawLine(x + w / 4 * 3, y + s * 1, x + w - 1, y + s * 1, SOLID, 0)
	lcd.drawLine(x + w / 4 * 2, y + s * 2, x + w - 1, y + s * 2, SOLID, 0)
	lcd.drawLine(x + w / 4 * 3, y + s * 3, x + w - 1, y + s * 3, SOLID, 0)
	lcd.drawLine(x + 1, y + s * 4, x + w - 1, y + s * 4, SOLID, 0)
	lcd.drawLine(x + w / 4 * 3, y + s * 5, x + w - 1, y + s * 5, SOLID, 0)
	lcd.drawLine(x + w / 4 * 2, y + s * 6, x + w - 1, y + s * 6, SOLID, 0)
	lcd.drawLine(x + w / 4 * 3, y + s * 7, x + w - 1, y + s * 7, SOLID, 0)

	-- Place voltage text [top, middle, bottom]
	lcd.drawText(x + w + 4, y - 2, string.format('%.2fv', battMax), SMLSIZE)
	lcd.drawText(x + w + 4, y + s * 4 - 2, string.format('%.2fv', (battMax - battMin) / 2 + battMin), SMLSIZE)
	lcd.drawText(x + w + 4, y + s * 8 - 3, string.format('%.2fv', battMin), SMLSIZE)

	-- Fill the battery
	for offset = 0, s * 8 - 2, 1 do
		if (offset * (battMax - battMin) / (s * 8 - 1) + battMin) < tonumber(batt / cell) then
			lcd.drawLine(x + 1, y + s * 8 - 1 - offset, x + w - 1, y + s * 8 - 1 - offset, SOLID, 0)
		end
	end
end

-- Current flying mode
local function drawModeTitle(x, y)
	if crsf then
		local fm = {
			['0'] = '---', ['!FS!'] = 'Failsafe', ['!ERR'] = 'Error',
			['STAB'] = 'Angle', ['MANU'] = 'Manual', ['HOR'] = 'Horizon', ['RTH'] = 'Return'
		}

		-- Make some prep to show good mode name
		modeText = string.gsub(mode, '%*', '')
		modeText = fm[string.sub(modeText, 1, 4)] or string.sub(modeText, 0, 1) .. string.lower(string.sub(modeText, 2))

		-- In BF 4.0+ flight mode ends with '*' when not armed, also check for errors
		isArmed = string.sub(mode, -1) ~= '*' and not string.match('!ERR WAIT 0', mode)
	else
		-- Search mode in settings array and show it according to switch position
		modeText = settings.mode.list[(mode + 1024) / 20.48 / 50 + 1] or 'Unknown'

		-- Check if quad is armed by a switch
		isArmed = (armed + 1024) / 20.48 == settings.arm.target and link > 0
	end

	-- Set up text in top middle of the screen
	lcd.drawText(x - #modeText * 2.5, y, modeText, SMLSIZE)
end

-- Animated Quadcopter propellor (zero coords for top left)
local function drawPropellor(x, y, invert)
	if (not isArmed and not invert) or (isArmed and animation == (invert and 2 or 0)) then
		lcd.drawLine(x + 1, y + 9, x + 9, y + 1, SOLID, FORCE)
		lcd.drawLine(x + 1, y + 10, x + 8, y + 1, SOLID, FORCE)
	elseif (isArmed and animation == 1) then
		lcd.drawLine(x, y + 5, x + 9, y + 5, SOLID, FORCE)
		lcd.drawLine(x, y + 4, x + 9, y + 6, SOLID, FORCE)
	elseif (not isArmed and invert) or (isArmed and animation == (invert and 0 or 2)) then
		lcd.drawLine(x + 1, y + 1, x + 9, y + 9, SOLID, FORCE)
		lcd.drawLine(x + 1, y + 2, x + 10, y + 9, SOLID, FORCE)
	elseif (isArmed and animation == 3) then
		lcd.drawLine(x + 5, y, x + 5, y + 10, SOLID, FORCE)
		lcd.drawLine(x + 6, y, x + 4, y + 10, SOLID, FORCE)
	end
end

-- A sexy helper to draw a 30x30 quadcopter
local function drawQuadcopter(x, y)
  	-- A little frame counter to help prop drawing
	animation = math.fmod(math.ceil(tick * 8), 4)

	-- Top left to bottom right
	lcd.drawLine(x + 4, y + 4, x + 26, y + 26, SOLID, FORCE)
	lcd.drawLine(x + 4, y + 5, x + 25, y + 26, SOLID, FORCE)
	lcd.drawLine(x + 5, y + 4, x + 26, y + 25, SOLID, FORCE)

	-- Bottom left to top right
	lcd.drawLine(x + 4, y + 26, x + 26, y + 4, SOLID, FORCE)
	lcd.drawLine(x + 4, y + 25, x + 25, y + 4, SOLID, FORCE)
	lcd.drawLine(x + 5, y + 26, x + 26, y + 5, SOLID, FORCE)

	-- Middle of Quad
	lcd.drawRectangle(x + 11, y + 11, 9, 9, SOLID)
	lcd.drawRectangle(x + 12, y + 12, 7, 7, SOLID)
	lcd.drawRectangle(x + 13, y + 13, 5, 5, SOLID)

	-- Draw propellors [top left, bottom right, top right, bottom left]
	drawPropellor(x, y, false)
	drawPropellor(x + 20, y + 20, false)
	drawPropellor(x + 20, y, true)
	drawPropellor(x, y + 20, true)

	-- ARMED text
	lcd.drawText(x + 3, y + 12, isArmed and 'ARMED' or '', SMLSIZE + BLINK)
end

-- Current quad battery volatage at the bottom
local function drawVoltageText(x, y)
	lcd.drawText(x + (voltage >= 10 and 4 or 7), y, string.format('%.2f', voltage), MIDSIZE)
	lcd.drawText(x + (voltage >= 10 and 35 or 31), y + 4, 'v', MEDSIZE)
end

-- Current capacity drained value at the bottom
local function drawCapacityUsed(x, y)
	lcd.drawText(x + 14 - #tostring(mah) * 3, y, mah, MIDSIZE)
	lcd.drawText(x + 14 + #tostring(mah) * 4, y - 1, 'm', SMLSIZE)
	lcd.drawText(x + 14 + #tostring(mah) * 4, y + 5, 'ah', SMLSIZE)
end

-- Signal strength value and graph
local function drawLink(x, y)
	-- Draw main border
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawRectangle(x, y + 9, 44, 15, SOLID)

	-- Draw caption and value, blink if low
	lcd.drawText(x + 2, y + 2, (crsf and 'LQ' or 'RSSI') .. ':', SMLSIZE)
	lcd.drawText(x + (crsf and 15 or 24), y + 2, link, SMLSIZE + (link > 50 and 0 or BLINK))

	if link > 0 then
		-- Add dots to background if showing LQ
		if crsf then
			for i = 2, 41, 2 do
				for j = 1, 11, 2 do
					lcd.drawLine(x + 1 + i, y + 10 + j, x + 1 + i, y + 10 + j, SOLID, FORCE)
				end
			end
		end

		-- Fill the bar (vertiсally or diagonally), on crsf start from 50 (70 is return back value)
		for i = 2, (crsf and math.max(link * 2 - 100 * (link >= 200 and 5 or 1), 0) or link) + 2, 2 do
			lcd.drawLine(x + 1 + i / 2.5, y + (crsf and 10 or 20 - i / 10), x + 1 + i / 2.5, y + 22, SOLID, FORCE)
		end

		-- Last pixel filling
		if link % 200 >= 99 then
			lcd.drawLine(x + 42, y + 10, x + 42, y + 22, SOLID, FORCE)
		end

		-- Link icon visible if value > 0
		lcd.drawLine(x + 35, y + 3, x + 35, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 36, y + 2, x + 40, y + 2, SOLID, FORCE)
		lcd.drawLine(x + 41, y + 3, x + 41, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 36, y + 5, x + 36, y + 5, SOLID, FORCE)
		lcd.drawLine(x + 37, y + 4, x + 39, y + 4, SOLID, FORCE)
		lcd.drawLine(x + 40, y + 5, x + 40, y + 5, SOLID, FORCE)
		lcd.drawLine(x + 38, y + 7, x + 38, y + 7, SOLID, FORCE)
	end
end

-- Transmitter output power and frequency
local function drawOutput(x, y)
	local grid = {{'4', '50', '150'}, {'0', '25', '50', '100', '100F', '150', '200', '250', '333F', '500', 'D250', 'D500', 'F500', 'F1000', 'D50'}}

	-- Prepare final values for display
	local pwr = tostring(getValue('TPWR'))
	local fmd = grid[elrs and 2 or 1][getValue('RFMD') + 1]

	-- Draw main border
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawRectangle(x, y + 9, 44, 15, SOLID)

	-- Draw caption and blanks
	lcd.drawText(x + 2, y + 2, 'Output', SMLSIZE)
	lcd.drawText(x + 7, y + 16, 'mw', SMLSIZE)
	lcd.drawText(x + 28, y + 16, 'hz', SMLSIZE)

	-- Draw output values
	lcd.drawText(x + 13 - #pwr * 2.5, y + 11, pwr, SMLSIZE)
	lcd.drawText(x + 34 - #fmd * 3, y + 11, fmd, SMLSIZE)

	-- Draw icon
	lcd.drawLine(x + 35, y + 6, x + 35, y + 7, SOLID, FORCE)
	lcd.drawLine(x + 37, y + 5, x + 37, y + 7, SOLID, FORCE)
	lcd.drawLine(x + 39, y + 4, x + 39, y + 7, SOLID, FORCE)
	lcd.drawLine(x + 41, y + 3, x + 41, y + 7, SOLID, FORCE)

	-- Small touch to fix overlaping 'hz'
	lcd.drawPoint(x + 28, y + 17, SOLID, FORCE)
end

-- Flight timer counts from black to white
local function drawFlightTimer(x, y)
	-- Draw main border
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

	-- Draw caption and timer text
	lcd.drawText(x + 2, y + 2, 'Fly Timer', SMLSIZE)
	lcd.drawTimer(x + 2, y + 11, math.abs(timerLeft), DBLSIZE + (timerLeft >= 0 and 0 or BLINK))

	-- Fill the background
	for offset = 1, timerLeft / timerMax * 42, 1 do
		lcd.drawLine(x + offset, y + 10, x + offset, y + 27, SOLID, 0)
	end
end

-- Current GPS position and sat count
local function drawPosition(x, y)
	local sats = getValue(settings.telemetry.satcount)

	-- Draw main border
	lcd.drawRectangle(x, y, 44, 10)
	lcd.drawRectangle(x, y + 9, 44, 20, SOLID)

	-- Draw caption and GPS coordinates
	lcd.drawText(x + 2, y + 2, 'GPS', SMLSIZE)
	lcd.drawText(x + 4, y + 12, string.sub(string.format('%09.6f', pos.lat), 0, 8), SMLSIZE)
	lcd.drawText(x + 4, y + 20, string.sub(string.format('%09.6f', pos.lon), 0, 8), SMLSIZE)

	-- Blink if telemetry is lost
	if pos.lost then
		lcd.drawFilledRectangle(x + 1, y + 10, 42, math.ceil(tick) ~= 1 and 18 or 0)
	elseif sats ~= 0 then
		-- Draw sats count if telemetry source exists
		lcd.drawText(x + 36 - #tostring(sats) * 5, y + 2, sats, SMLSIZE + (sats >= 3 and 0 or BLINK))

		-- Show satellite icon
		lcd.drawLine(x + 40, y + 6, x + 37, y + 3, SOLID, FORCE)
		lcd.drawLine(x + 40, y + 2, x + 36, y + 6, SOLID, FORCE)
		lcd.drawLine(x + 40, y + 3, x + 37, y + 6, SOLID, FORCE)
		lcd.drawLine(x + 40, y + 4, x + 38, y + 6, SOLID, FORCE)
		lcd.drawLine(x + 39, y + 7, x + 41, y + 7, SOLID, FORCE)
	end
end

------- MAIN FUNCTIONS -------

local function gatherInput(event)
	-- Get RX signal strength source
	link = crsf and getValue('TQly') or getRSSI()

	-- Get current transmitter voltage
	txvoltage = getValue('tx-voltage')

	-- Get quad battery voltage source
	voltage = getValue(crsf and 'RxBt' or settings.battery.voltage)

	-- Get quad battery capacity drained value in mAh
	capacity = getValue(crsf and 'Capa' or settings.battery.used)

	-- ARM switch source
	armed = getValue(settings.arm.switch)

	-- Current fly mode source
	mode = getValue(crsf and 'FM' or settings.mode.switch)

	-- Check if GPS telemetry exists and get position
	gps = getFieldInfo('GPS') and getValue('GPS') or false

	-- Animation helper
	tick = math.fmod(getTime() / 100, 2)

	-- Differentiate what exact long-range module is used
	if crsf and elrs == nil then
		local shift, command, data = 3, crossfireTelemetryPop()

		if command == 0x29 and data[2] == 0xEE then
			while data[shift] ~= 0 do
				shift = shift + 1
			end

			elrs = (data[shift + 1] == 0x45 and data[shift + 2] == 0x4c and data[shift + 3] == 0x52 and data[shift + 4] == 0x53)
		elseif math.ceil(tick) == 1 then
			crossfireTelemetryPush(0x28, {0x00, 0xEA})
		end
	end

	-- Change screen if EXIT button pressed
	if event == EVT_EXIT_BREAK then
		screen.alt = not screen.alt
	end
end

local function background()
	local timerName = settings.telemetry.timer - 1

	-- Follow ARM state if timer is not configured
	if model.getTimer(timerName).mode <= 1 then
		model.setTimer(timerName, {mode = isArmed and 1 or 0})
	end

	-- Get seconds left in model timer
	timerLeft = model.getTimer(timerName).value
	timerMax = math.max(timerLeft, timerMax or 0)

	-- Store last capacity drained value
	mah = link ~= 0 and capacity or mah or 0

	-- Check if GPS data coming
	if type(gps) == 'table' then
		pos = gps
	elseif pos.lat ~= 0 then
		pos.lost = true
	end
end

local function run(event)
	-- Gather telemetry data
	gatherInput(event)

	-- Begin drawing
	lcd.clear()

	-- Draw tx voltage in upper left courner
	drawTransmitterVoltage(0, 0, screen.w / 10)

	-- Draw model name centered at the upper top of the screen
	lcd.drawText(screen.w / 2 - #modelName * 2.5, 0, modelName, SMLSIZE)

	-- Draw time in top right courner
	drawTime(screen.w - 29, 0)

	-- Draw a horizontal line seperating the header
	lcd.drawLine(0, 7, screen.w - 1, 7, SOLID, FORCE)

	-- Draw voltage battery graphic in left side
	drawVoltageImage(3, 8, screen.w / 10, screen.h - 8)

	-- Draw fly mode centered above sexy quad
	drawModeTitle(screen.w / 2, screen.h / 4 - 7)

	-- Draw sexy quadcopter animated in center
	drawQuadcopter(screen.w / 2 - 17,  screen.h / 2 - 14)

	-- Draw rx signal strength or transmitter output at right top
	drawData = (crsf and screen.alt) and drawOutput or drawLink
	drawData(screen.w - 44, (screen.h - 8) / 4 - 5)

	-- Draw flight timer or GPS position at right bottom
	drawData = (gps and screen.alt) and drawPosition or drawFlightTimer
	drawData(screen.w - 44, (screen.h - 8) / 4 * 3 - 8)

	-- Draw battery capacity drained or current voltage at bottom middle
	drawData = (mah ~= 0 and screen.alt) and drawCapacityUsed or drawVoltageText
	drawData(screen.w / 2 - 21, screen.h - (screen.h - 8) / 4 + 1)
end

local function init()
	-- Detect if long-range module is used
	crsf = crossfireTelemetryPush and crossfireTelemetryPush() ~= nil

	-- Model name from the radio
	modelName = model.getInfo()['name']

	-- Radio battery min-max range
	radio = getGeneralSettings()

	-- Screen size for positioning
	screen = {w = LCD_W, h = LCD_H}

	-- Store GPS coordinates
	pos = {lat = 0, lon = 0}
end

return { init = init, run = run, background = background }
