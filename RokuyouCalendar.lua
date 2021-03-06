-- RokuyouCalendar v1.0 by forgetaz (forgetaz@outlook.com)
-- This work is licensed under GNU General Public License v2.0.
-- Encoding Shift-jis
local function RokuyouCalendar()
	local RC = {
		MaxDays = 42,
		CalendarYear = 0,
		CalendarMonth = 0,
		RokuyouColors = {},
		Holidays = {},
		ContainerWidth = 0,
		DaySizeRatio = 0,
		GoldenRatio = 0,
		CellWidth = 0,
		CellY = 0,
		CellX = 0,
		CellHeight = 0,
		RokuyouCellHeight = 0,
		CellPadding = 10,
		ContainerPaddingLeft = 10,
		NotRealTime = false,
		Weekname = 'Week%d',
		Dayname = 'mday%d',
		Rokname = 'rokuyou%d',
		Dows = {},
		UpdatedTime = os.date('*t', os.time({year=1970, month=1, day=1})),
		CalendarTime = nil,
		RealTime = nil,
		ExecuteTime = nil,
		CacheName = 'RokuyouData',
		CriticalError = 0,
		CriticalErrorMsg = 'Script error has Occurred. Please contact the author!'
		.."\r\n"..'This skin will be closed automatically.',
		TestFlg = 0,
		ShowErrorMessage = function(SELF, m, group)
			if group ~= nil then
				SKIN:Bang('!HideMeterGroup', group)
			end
			SELF:setOption('Message', 'Text', m)
			SELF:setOption('Message', 'w', SELF.ContainerWidth)
			SELF:setOption('Message', 'MeterStyle', 'ErrorStyle' )
		end,
		inRokuyou = function(SELF, y, m , d)
			if SELF.CacheName ~= '' then
				local cache = SELF:getCache(SELF.CacheName)
				local temp = y..'-'..m..'-'..d

				if cache[temp] ~= nil then
					return cache[temp]
				end

				cache[temp] = SELF:getRokuyou(y, m, d)
				SELF:setCache(SELF.CacheName, cache)
				return cache[temp]
			end

			return SELF:getRokuyou(y, m, d)
		end,
		getRokuyouCal = function(SELF, y, m)
			y = SELF:toInt(y)
			m = SELF:toInt(m)
			local prevmonth
			local prevyear
			local nextmonth
			local nextyear
			local Results = {}
			--prevmonthdays
			local tmpTime = os.date('*t', os.time({year = y, month = m, day = 0}))
			local prevmonthdays = tmpTime.wday
			local prevLastDay = tmpTime.day
			--prevmonth--prevyear
			prevmonth = tmpTime.month
			prevyear = tmpTime.year
			tmpTime = os.date('*t', os.time({year = y, month = m, day = 32}))
			--nextmonth--nextyear
			nextmonth = tmpTime.month
			nextyear = tmpTime.year
			--prevLastDay
			tmpTime = os.date('*t', os.time({year = y, month = m+1, day = 0}))
			local lastDay = tmpTime.day
			local firstDay = prevLastDay - prevmonthdays + 1
			--prevmonth
			--Results[CalendarCellNumber]={In Current Month, Day, Rokuyou Number}
			for i = 1, prevmonthdays do
				Results[i] = {false, (firstDay + i - 1), SELF:inRokuyou(prevyear, prevmonth, firstDay+i - 1)}
			end
			--currentmonth
			for i = 1, lastDay do
				Results[prevmonthdays + i] = {true, i, SELF:inRokuyou(y, m, i)}
			end
			--nextmonth
			local tmp = prevmonthdays + lastDay
			local max = SELF.MaxDays - tmp
			for i = 1, max do
				Results[tmp + i] = {false, i, SELF:inRokuyou(nextyear, nextmonth, i)}
			end

			return Results
		end,

		SetCurrentDate = function(SELF, y, m)
			--Get Real Time
			SELF.RealTime = os.date('*t')
			--Get Calendar Time
			SELF.CalendarTime = os.date('*t', os.time({year = y, month = m, day = 1}))
			SELF.NotRealTime = true
			--Check Real Time
			if SELF.RealTime.year == SELF.CalendarTime.year and SELF.RealTime.month == SELF.CalendarTime.month then
				SELF.CalendarTime = SELF.RealTime
				SELF.NotRealTime = false
			end

			local NeedUpdate = false
			--if current month and wrong day
			if SELF.NotRealTime == false and SELF.UpdatedTime.day ~= SELF.RealTime.day then
				NeedUpdate = true
			end

			if SELF.CalendarYear ~= SELF.CalendarTime.year then
				SELF.Holidays = {}
				SELF.CalendarYear = SELF.CalendarTime.year
				SELF.Holidays = SELF:getHolidays()
				NeedUpdate = true
			end

			if SELF.CalendarMonth ~= SELF.CalendarTime.month then
				SELF.CalendarMonth = SELF.CalendarTime.month
				NeedUpdate = true
			end

			if NeedUpdate then
				SELF.UpdatedTime = SELF.CalendarTime
			end

			return NeedUpdate
		end,

		Previous = function(SELF)
			SELF:BtnAction(-1)
		end,

		Next = function(SELF)
			SELF:BtnAction(1)
		end,

		Today = function(SELF)
			SELF:BtnAction(0)
		end,

		BtnAction = function(SELF, flg)
			SELF:BtnChangeState(false)
			if SELF:PrepareCalendar(flg) then
				SELF:CreateCalendar()
			end
			SELF:BtnChangeState(true)
			SKIN:Bang('!Update')
		end,

		BtnChangeState = function(SELF, b)
			if b then
				SELF:ShowMeter('PreviousBtn')
				SELF:ShowMeter('NextBtn')
				if SELF.NotRealTime then
					SELF:ShowMeter('CurrentDateBtn')
				end
			else
				SELF:HideMeter('PreviousBtn')
				SELF:HideMeter('NextBtn')
				SELF:HideMeter('CurrentDateBtn')
			end
		end,

		PrepareCalendar = function(SELF, n)
			local t
			if n == 0 then
				t = os.date('*t')
			else
				t = os.date('*t', os.time({year = SELF.CalendarYear, month = SELF.CalendarMonth + n, day = 1}))
			end

			SELF:setOption('RokuyouLua', 'curYear', t.year)
			SELF:setOption('RokuyouLua', 'curMonth', t.month)
			return SELF:SetCurrentDate(t.year, t.month)
		end,

		GetRokuyou = function(SELF, s)
			local rs = {"大安", "赤口", "先勝", "友引", "先負", "仏滅"}
			return rs[tonumber(s)+1]
		end,

		GetRokuyouColor = function(SELF, s)
			return SELF.RokuyouColors[tonumber(s)]
		end,

		isHoliday= function(SELF, n)
			n = tonumber(n)
			if SELF.Holidays[SELF.CalendarYear][SELF.CalendarMonth] == nil or SELF.Holidays[SELF.CalendarYear][SELF.CalendarMonth][n] == nil then
				return nil
			end

			return SELF.Holidays[SELF.CalendarYear][SELF.CalendarMonth][n]
		end,

		CreateCalendar = function(SELF)
			local Cals = SELF:getRokuyouCal(SELF.CalendarYear,SELF.CalendarMonth)
			--Check days = 42 calendar cells
			if table.maxn(Cals) ~= 42 then
				SELF:ShowErrorMessage(SELF.CriticalErrorMsg, 'CalendarCell')
				SELF.CriticalError = SELF.CriticalError + 1
				return
			end

			local DayMeter
			local Linecount
			local CellHeightBase
			local tmp
			local Rokmeter
			local TempY
			local HolidayDesc
			local RokOtherMonthStyle
			local CurrentDayStyle
			local DateStyle
			local CurrentDay = SELF.CalendarTime.day

			SELF:HideMeter('MeterDay')
			SELF:HideMeter('MeterDayName')
			SELF:HideMeter('MeterDOW')
			SELF:HideMeter('MeterDOWName')
			SELF:setOption('MeterYear','Text',SELF.CalendarTime.year)
			SELF:setOption('MeterMonth','Text',SELF.CalendarTime.month)
			if SELF.NotRealTime ~= true then
				SELF:ShowMeter('MeterDay')
				SELF:ShowMeter('MeterDayName')
				SELF:ShowMeter('MeterDOW')
				SELF:ShowMeter('MeterDOWName')
				SELF:setOption('MeterDay','Text',SELF.CalendarTime.day)
				SELF:setOption('MeterDOW','Text',SELF.Dows[SELF.CalendarTime.wday])
			end

			local DayY = SELF.CellHeight+ SELF.CellY
			CellHeightBase = (SELF.CellHeight + SELF.RokuyouCellHeight)/2
			for i = 1, 42 do
				--Cell size
				Linecount = string.gsub((i - 1) / 7, '(%d)', '%1')
				Linecount = tonumber(string.format('%d', Linecount))
				tmp = string.format('%dr', SELF.CellWidth)
				if (i % 7) == 1 then
					tmp = string.format('%d', SELF.CellX+SELF.CellPadding)
				end
				TempY = DayY +(Linecount * CellHeightBase)
				if Linecount > 0 then
					TempY = DayY +(Linecount*2 * CellHeightBase)
				end
				--Day
				DateStyle = 'DateStyle'
				CurrentDayStyle = ''
				if Cals[i][1] then
					RokOtherMonthStyle = ''
					HolidayDesc = SELF:isHoliday(Cals[i][2])
					if HolidayDesc ~= nil
						or i % 7 == 1
						or i % 7 == 0 then
						DateStyle = 'DateStyle|HolidayStyle'
						if i % 7 == 0 then
							DateStyle = DateStyle..'|SaturdayStyle'
						end
					end

					if CurrentDay == Cals[i][2] and SELF.NotRealTime == false then
						CurrentDayStyle = '|CurrentDayStyle'
					end
				else
					HolidayDesc = nil
					DateStyle = DateStyle..'|OtherMonthStyle'
					RokOtherMonthStyle = '|OtherMonthStyle|RokuyouOtherMonthStyle'
				end
				--Create Day cell
				DayMeter = SELF.Dayname:format(i)
				SELF:setOption(DayMeter,'Text',Cals[i][2])
				SELF:setOption(DayMeter, 'MeterStyle', DateStyle..CurrentDayStyle )
				SELF:setOption(DayMeter, 'X', tmp)
				SELF:setOption(DayMeter, 'Y',TempY)
				SELF:setOption(DayMeter, 'W', SELF.CellWidth - SELF.CellPadding)
				SELF:setOption(DayMeter, 'H', SELF.CellHeight)
				--Create Rokuyou cell
				Rokmeter = SELF.Rokname:format(i)
				SELF:setOption(Rokmeter, 'Text', SELF:GetRokuyou(Cals[i][3]))
				SELF:setOption(Rokmeter, 'MeterStyle', SELF:GetRokuyouColor(Cals[i][3])..RokOtherMonthStyle..CurrentDayStyle)
				SELF:setOption(Rokmeter, 'X', tmp)
				SELF:setOption(Rokmeter, 'Y', TempY)
				SELF:setOption(Rokmeter, 'W', SELF.CellWidth - SELF.CellPadding)
				SELF:setOption(Rokmeter, 'H', SELF.RokuyouCellHeight)
				if HolidayDesc ~= nil then
						SELF:setOption(DayMeter, 'ToolTipText', HolidayDesc )
						SELF:setOption(Rokmeter, 'ToolTipText', HolidayDesc )
				end
			end

			if SELF.CalendarYear == SELF.RealTime.year and SELF.CalendarMonth == SELF.RealTime.month then
				SELF:HideMeter('CurrentDateBtn')
				SELF.NotRealTime = false
			end

			return
		end,

		--Calc holidays of current year.
		getHolidays = function(SELF)
			--Check
			if table.maxn(SELF.Holidays) > 0 and SELF.Holidays[SELF.CalendarYear] ~= nil then
				return SELF.Holidays
			end

			local hurikae = '振替休日'

			SELF.Holidays[SELF.CalendarYear] = {}
			--元旦
			SELF.Holidays[SELF.CalendarYear][1] = {}
			SELF.Holidays[SELF.CalendarYear][1][1] = '元日'
			--成人の日　1月第二月曜日
			local tmp = os.date('*t', os.time({year=SELF.CalendarYear, month=1, day=0})).wday
			local seijin = 14 - (tmp - 2)
			if tmp == 1 then
				seijin = 8
			end
			SELF.Holidays[SELF.CalendarYear][1][seijin] = '成人の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=1, day=seijin})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][1][seijin+1] = hurikae
			end
			--建国記念の日 2/11
			SELF.Holidays[SELF.CalendarYear][2] = {}
			SELF.Holidays[SELF.CalendarYear][2][11] = '建国記念の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=2, day=11})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][2][12] = hurikae
			end
			--天皇誕生日 2/23
			SELF.Holidays[SELF.CalendarYear][2][23] = '天皇誕生日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=2, day=24})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][2][24] = hurikae
			end
			--春分の日
			tmp = os.date('*t', os.time{
				month = 3,
				day = math.floor(20.8431 + 0.242194 * (SELF.CalendarYear - 1980) - math.floor((SELF.CalendarYear - 1980) / 4)),
				year =SELF.CalendarYear
			})
			SELF.Holidays[SELF.CalendarYear][tmp.month] = {}
			SELF.Holidays[SELF.CalendarYear][tmp.month][tmp.day] = '春分の日'
			if tmp.wday == 7 then
				SELF.Holidays[SELF.CalendarYear][tmp.month][tmp.day+1] = hurikae
			end
			--昭和の日 4月29日
			SELF.Holidays[SELF.CalendarYear][4] = {}
			SELF.Holidays[SELF.CalendarYear][4][29] = '昭和の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=4, day=29})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][4][30] = hurikae
			end
			--憲法記念日
			--みどりの日
			--こどもの日
			SELF.Holidays[SELF.CalendarYear][5] = {}
			SELF.Holidays[SELF.CalendarYear][5][3] = '憲法記念日'
			SELF.Holidays[SELF.CalendarYear][5][4] = 'みどりの日'
			SELF.Holidays[SELF.CalendarYear][5][5] = 'こどもの日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=5, day=3})).wday == 7
				or os.date('*t', os.time({year=SELF.CalendarYear, month=5, day=4})).wday == 7
				or os.date('*t', os.time({year=SELF.CalendarYear, month=5, day=5})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][5][6] = hurikae
			end
			--海の日　7月第三月曜日 2021年対応
			local uminohi = 22
			if SELF.CalendarYear ~= 2021 then
				tmp = os.date('*t', os.time({year=SELF.CalendarYear, month=7, day=0})).wday
				uminohi = 21 - (tmp - 2)
				if tmp == 1 then
					uminohi = 15
				end
			end
			SELF.Holidays[SELF.CalendarYear][7] = {}
			SELF.Holidays[SELF.CalendarYear][7][uminohi] = '海の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=7, day=uminohi})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][7][uminohi+1] = hurikae
			end
			--スポーツの日　2020/7/24 or 10月第二月曜日 or 2021/7/23
			local Sport = 24
			if SELF.CalendarYear == 2021 then
				Sport = 23
				SELF.Holidays[SELF.CalendarYear][7][Sport] = 'スポーツの日'
			elseif SELF.CalendarYear == 2020 then
				SELF.Holidays[SELF.CalendarYear][7][Sport] = 'スポーツの日'
			else
				tmp = os.date('*t', os.time({year=SELF.CalendarYear, month=10, day=0})).wday
				Sport = 14 - (tmp - 2)
				if tmp == 1 then
					Sport = 8
				end
				SELF.Holidays[SELF.CalendarYear][10] = {}
				SELF.Holidays[SELF.CalendarYear][10][Sport] = 'スポーツの日'
				if os.date('*t', os.time({year=SELF.CalendarYear, month=10, day=Sport})).wday == 7 then
					SELF.Holidays[SELF.CalendarYear][10][Sport+1] = hurikae
				end
			end
			--山の日 8/10 2021年対応
			SELF.Holidays[SELF.CalendarYear][8] = {}
			if SELF.CalendarYear == 2021 then
				SELF.Holidays[SELF.CalendarYear][8][8] = '山の日'
				SELF.Holidays[SELF.CalendarYear][8][9] = hurikae
			else
				SELF.Holidays[SELF.CalendarYear][8][10] = '山の日'
				if os.date('*t', os.time({year=SELF.CalendarYear, month=8, day=10})).wday == 7 then
					SELF.Holidays[SELF.CalendarYear][8][11] = hurikae
				end
			end
			--敬老の日
			tmp = os.date('*t', os.time({year=SELF.CalendarYear, month=9, day=0})).wday
			local keirou = 21 - (tmp - 2)
			if tmp == 1 then
				keirou = 15
			end
			SELF.Holidays[SELF.CalendarYear][9] = {}
			SELF.Holidays[SELF.CalendarYear][9][keirou] = '敬老の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=7, day=keirou})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][9][keirou+1] = hurikae
			end
			--秋分の日
			tmp = os.date('*t', os.time{
				month = 9,
				day = math.floor(23.2488 + 0.242194 * (SELF.CalendarYear - 1980) - math.floor((SELF.CalendarYear - 1980) / 4)),
				year = SELF.CalendarYear
			})
			SELF.Holidays[SELF.CalendarYear][tmp.month][tmp.day] = '秋分の日'
			if tmp.wday == 7 then
				SELF.Holidays[SELF.CalendarYear][tmp.month][tmp.day+1] = hurikae
			end
			--文化の日 11/3
			SELF.Holidays[SELF.CalendarYear][11] = {}
			SELF.Holidays[SELF.CalendarYear][11][3] = '文化の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=11, day=3})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][11][4] = hurikae
			end
			--勤労感謝の日 11/23
			SELF.Holidays[SELF.CalendarYear][11][23] = '勤労感謝の日'
			if os.date('*t', os.time({year=SELF.CalendarYear, month=11, day=23})).wday == 7 then
				SELF.Holidays[SELF.CalendarYear][11][24] = hurikae
			end

			return SELF.Holidays
		end
	}

	return RC
end

return RokuyouCalendar()