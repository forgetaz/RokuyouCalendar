--Module Qreki
--Author forgetaz
--2020-09-03
-- Encoding Shift-jis
--[[
H.TAKANO(高野 英明) さんによる旧暦計算サンプルスクリプトが元でどなたか
（いろいろなところで見ることができるのではっきりわかりませんでした。）の
PHP移植版を参考にしながらLuaに移植してみました。
H.TAKANOさんのオリジナルは、以下から入手できます。
https://www.vector.co.jp/soft/dos/personal/se016093.html
また、ご本人が公開されているものかわからないのですが、スクリプトの説明は以下からも見ることができます。
http://memopad.bitter.jp/web/app/calendar/QREKI.html#sec-01

PHP版は、どこが元なのかわからなかったので、"qreki.php" で検索してください。

※注意
変更(修正とは言っていない)を行っているので必ずしも当然の結果が得られるとは限りません。
また、コメントは全部削除してあるので元スクリプトを参照してください。
///
作者と別言語移植者に多大なる感謝を!!!!
]]
local function Qreki()
	local Q = {
		getRokuyou = function(SELF, year, month, day)
			local temp = SELF:calcKyureki(year, month, day)
			return (temp[2] + temp[3]) % 6
		end,
		calcKyureki = function(SELF, year, mon, day)
			local tm0 = SELF:YMDT2JD(year, mon, day, 0, 0, 0)
			local chu = {}
			local nibun = SELF:beforeNibun(tm0)
			chu[0] = {}
			chu[0][0] = nibun[0]
			chu[0][1] = nibun[1]
			local cchu
			local ti = 1
			for i = 1, 3 do
				chu[i] = {}
				cchu = SELF:calcChu(chu[i - 1][0] + 32.0)
				chu[i][0] = cchu[0]
				chu[i][1] = cchu[1]
			end

			local saku = {}
			saku[0] = SELF:calcSaku(chu[0][0])
			local tm
			for i = 1,  4 do
				tm = saku[i - 1]
				tm = tm + 30.0
				saku[i] = SELF:calcSaku(tm)
				if (math.abs(SELF:int(saku[i - 1]) - SELF:int(saku[i])) <= 26.0) then
					saku[i] = SELF:calcSaku(saku[i - 1] + 35.0)
				end
			end

			if (SELF:int(saku[1]) <= SELF:int(chu[0][0])) then
				for i = 0, 4 do
					if saku[i + 1] == nil then
						saku[i + 1] = 0
					end
					saku[i] = saku[i + 1]
				end
				saku[4] = SELF:calcSaku(saku[3] + 35.0)
			elseif (SELF:int(saku[0]) > SELF:int(chu[0][0])) then
				for i = 4, 1, -1 do
					saku[i] = saku[i - 1]
				end
				saku[0] = SELF:calcSaku(saku[0] - 27.0)
			end

			local lap = 0
			if (SELF:int(saku[4]) <= SELF:int(chu[3][0])) then
				lap = 1
			end

			local m = {}
			m[0] = {}
			m[0][0] = SELF:int(chu[0][1] / 30.0) + 2
			if m[0][1] == nil then
				m[0][1] = 0
			end
			if (m[0][1] > 12) then
				m[0][0] = m[0][0] - 12
			end
			m[0][2] = SELF:int(saku[0])
			m[0][1] = 0

			for i = 1, 4 do
				if (lap == 1 and i ~= 1) then
					if (SELF:int(chu[i - 1][0]) <= SELF:int(saku[i - 1]) or SELF:int(chu[i - 1][0]) >= SELF:int(saku[i])) then
						m[i - 1][0] = m[i - 2][0]
						m[i - 1][1] = 1
						m[i - 1][2] = SELF:int(saku[i - 1])
						lap = 0
					end
				end
				if m[i] == nil then
					m[i] = {}
				end
				m[i][0] = m[i - 1][0] + 1
				if (m[i][0] > 12) then
					m[i][0] = m[i][0] - 12
				end
				m[i][2] = SELF:int(saku[i])
				m[i][1] = 0
			end

			local state = 0
			for i = 0, 4 do
				if (SELF:int(tm0) < SELF:int(m[i][2])) then
					state = 1
					break
				elseif (SELF:int(tm0) == SELF:int(m[i][2])) then
					state = 2
					break
				end
				ti = i
			end

			ti = ti + 1

			if state == 0 or state == 1 then
				ti = ti - 1
			end
			local kyureki = {}
			kyureki[1] = m[ti][1]
			kyureki[2] = m[ti][0]
			kyureki[3] = SELF:int(tm0) - SELF:int(m[ti][2]) + 1
			local a = SELF:JD2YMDT(tm0)
			kyureki[0] = a[0]
			if (kyureki[2] > 9 and kyureki[2] > a[1]) then
				kyureki[0] = kyureki[0] - 1
			end

			return kyureki
		end,
		calcChu = function(SELF, tm)
			local tm1 = SELF:int(tm)
			local tm2 = tm - tm1
			tm2 = tm2 - 9.0 / 24.0
			local t = (tm2 + 0.5) / 36525.0
			t = t + (tm1 - 2451545.0) / 36525.0
			local rm_sun = SELF:LONGITUDE_SUN(t)
			local rm_sun0 = 30.0 * SELF:int(rm_sun / 30.0)
			local delta_t1 = 0
			local delta_t2 = 1.0
			local delta_rm

			while math.abs(delta_t1 + delta_t2) > ( 1.0 / 86400.0 ) do
				t = (tm2 + 0.5) / 36525.0
				t = t + (tm1 - 2451545.0) / 36525.0
				rm_sun = SELF:LONGITUDE_SUN(t)

				delta_rm = rm_sun - rm_sun0

				if (delta_rm > 180.0) then
					delta_rm = delta_rm - 360.0
				elseif (delta_rm < -180.0) then
					delta_rm = delta_rm + 360.0
				end

				delta_t1 = SELF:int(delta_rm * 365.2 / 360.0)
				delta_t2 = delta_rm * 365.2 / 360.0
				delta_t2 = delta_t2 - delta_t1

				tm1 = tm1 - delta_t1
				tm2 = tm2 - delta_t2
				if (tm2 < 0) then
					tm2 = tm2 + 1.0
					tm1 = tm1 - 1.0
				end
			end

			local temp = {}
			temp[0] = tm2 + 9.0 / 24.0
			temp[0] = temp[0] + tm1
			temp[1] = rm_sun0

			return temp
		end,

		beforeNibun = function(SELF, tm)

			local tm1 = SELF:int(tm)
			local tm2 = tm - tm1

			tm2 = tm2 - 9.0 / 24.0

			local t = (tm2 + 0.5) / 36525.0

			t = t + (tm1 - 2451545.0) / 36525.0
			local rm_sun = SELF:LONGITUDE_SUN(t)
			local rm_sun0 = 90 * SELF:int(rm_sun / 90.0)
			local delta_t1
			local delta_t2
			local delta_rm

			while  true do

				t = (tm2 + 0.5) / 36525.0
				t = t + (tm1 - 2451545.0) / 36525.0
				rm_sun = SELF:LONGITUDE_SUN(t)
				delta_rm = rm_sun - rm_sun0

				if (delta_rm > 180.0) then
					delta_rm = delta_rm - 360.0
				elseif (delta_rm < -180.0) then
					delta_rm = delta_rm + 360.0
				end

				delta_t1 = SELF:int(delta_rm * 365.2 / 360.0)
				delta_t2 = delta_rm * 365.2 / 360.0
				delta_t2 = delta_t2 - delta_t1

				tm1 = tm1 - delta_t1
				tm2 = tm2 - delta_t2
				if (tm2 < 0) then
					tm2 = tm2 + 1.0
					tm1 = tm1 - 1.0
				end

				if math.abs(delta_t1 + delta_t2) <= ( 1.0 / 86400.0 ) then
					break
				end
			end

			local nibun = {}
			nibun[0] = tm2 + 9.0 / 24.0
			nibun[0] =nibun[0] +  tm1
			nibun[1] = rm_sun0

			return nibun
		end,

		calcSaku = function(SELF, tm)
			local lc = 1
			local tm1 = SELF:int(tm)
			local tm2 = tm - tm1
			tm2 = tm2 - 9.0 / 24.0
			local delta_t1
			local delta_t2
			local delta_rm
			local t
			local rm_sun
			local rm_moon
			while  true do
				t = (tm2 + 0.5) / 36525.0
				t = t + (tm1 - 2451545.0) / 36525.0
				rm_sun = SELF:LONGITUDE_SUN(t)
				rm_moon = SELF:LONGITUDE_MOON(t)
				delta_rm = rm_moon - rm_sun
				if lc == 1 and delta_rm < 0.0 then
					delta_rm = SELF:NORMALIZATION_ANGLE(delta_rm)
				elseif (rm_sun >= 0 and rm_sun <= 20 and rm_moon >= 300) then
					delta_rm = SELF:NORMALIZATION_ANGLE(delta_rm)
					delta_rm = 360.0 - delta_rm
				elseif (math.abs(delta_rm) > 40.0) then
					delta_rm = SELF:NORMALIZATION_ANGLE(delta_rm)
				end

				delta_t1 = SELF:int(delta_rm * 29.530589 / 360.0)
				delta_t2 = delta_rm * 29.530589 / 360.0
				delta_t2 = delta_t2 - delta_t1

				tm1 = tm1 - delta_t1
				tm2 = tm2 - delta_t2
				if (tm2 < 0.0) then
					tm2 = tm2 + 1.0
					tm1 = tm1 - 1.0
				end

				if (lc == 15 and math.abs(delta_t1 + delta_t2) > ( 1.0 / 86400.0 )) then
					tm1 = SELF:int(tm - 26)
					tm2 = 0
				elseif (lc > 30 and math.abs(delta_t1 + delta_t2) > ( 1.0 / 86400.0 )) then
					tm1 = tm
					tm2 = 0
					break
				end
				lc = lc + 1
				if math.abs(delta_t1 + delta_t2) <= ( 1.0 / 86400.0 ) then
					break
				end
			end

			return(tm2 + tm1 + 9.0 / 24.0)
		end,

		NORMALIZATION_ANGLE = function(SELF, angle)
			local angle1
			local angle2
			if  angle < 0.0 then
				angle1 = -angle
				angle2 = SELF:int(angle1 / 360.0)
				angle1 = angle1 - (360.0 * angle2)
				angle1 = 360.0 - angle1
			else
				angle1 = SELF:int(angle / 360.0)
				angle1 = angle - 360.0 * angle1
			end

			return(angle1)
		end,

		LONGITUDE_SUN = function(SELF, t)
			local PI = 3.141592653589793238462
			local k = PI / 180.0

			local ang = SELF:NORMALIZATION_ANGLE(31557.0 * t + 161.0)
			local th = .0004 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(29930.0 * t + 48.0)
			th = th + .0004 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(2281.0 * t + 221.0)
			th = th + .0005 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(155.0 * t + 118.0)
			th = th + .0005 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(33718.0 * t + 316.0)
			th = th + .0006 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(9038.0 * t + 64.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(3035.0 * t + 110.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(65929.0 * t + 45.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(22519.0 * t + 352.0)
			th = th + .0013 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(45038.0 * t + 254.0)
			th = th + .0015 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(445267.0 * t + 208.0)
			th = th + .0018 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(19.0 * t + 159.0)
			th = th + .0018 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(32964.0 * t + 158.0)
			th = th + .0020 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(71998.1 * t + 265.1)
			th = th + .0200 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(35999.05 * t + 267.52)
			th = th - 0.0048 * t * math.cos(k * ang)
			th = th + 1.9147 * math.cos(k * ang)

			ang = SELF:NORMALIZATION_ANGLE(36000.7695 * t)
			ang = SELF:NORMALIZATION_ANGLE(ang + 280.4659)
			th = SELF:NORMALIZATION_ANGLE(th + ang)

			return(th)
		end,
		LONGITUDE_MOON = function(SELF, t)
			local PI = 3.141592653589793238462
			local k = PI / 180.0
			local ang = SELF:NORMALIZATION_ANGLE(2322131.0 * t + 191.0)
			local th = .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(4067.0 * t + 70.0)
			th = th + .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(549197.0 * t + 220.0)
			th = th + .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1808933.0 * t + 58.0)
			th = th + .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(349472.0 * t + 337.0)
			th = th + .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(381404.0 * t + 354.0)
			th = th + .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(958465.0 * t + 340.0)
			th = th + .0003 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(12006.0 * t + 187.0)
			th = th + .0004 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(39871.0 * t + 223.0)
			th = th + .0004 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(509131.0 * t + 242.0)
			th = th + .0005 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1745069.0 * t + 24.0)
			th = th + .0005 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1908795.0 * t + 90.0)
			th = th + .0005 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(2258267.0 * t + 156.0)
			th = th + .0006 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(111869.0 * t + 38.0)
			th = th + .0006 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(27864.0 * t + 127.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(485333.0 * t + 186.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(405201.0 * t + 50.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(790672.0 * t + 114.0)
			th = th + .0007 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1403732.0 * t + 98.0)
			th = th + .0008 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(858602.0 * t + 129.0)
			th = th + .0009 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1920802.0 * t + 186.0)
			th = th + .0011 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1267871.0 * t + 249.0)
			th = th + .0012 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1856938.0 * t + 152.0)
			th = th + .0016 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(401329.0 * t + 274.0)
			th = th + .0018 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(341337.0 * t + 16.0)
			th = th + .0021 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(71998.0 * t + 85.0)
			th = th + .0021 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(990397.0 * t + 357.0)
			th = th + .0021 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(818536.0 * t + 151.0)
			th = th + .0022 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(922466.0 * t + 163.0)
			th = th + .0023 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(99863.0 * t + 122.0)
			th = th + .0024 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1379739.0 * t + 17.0)
			th = th + .0026 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(918399.0 * t + 182.0)
			th = th + .0027 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1934.0 * t + 145.0)
			th = th + .0028 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(541062.0 * t + 259.0)
			th = th + .0037 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1781068.0 * t + 21.0)
			th = th + .0038 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(133.0 * t + 29.0)
			th = th + .0040 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1844932.0 * t + 56.0)
			th = th + .0040 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1331734.0 * t + 283.0)
			th = th + .0040 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(481266.0 * t + 205.0)
			th = th + .0050 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(31932.0 * t + 107.0)
			th = th + .0052 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(926533.0 * t + 323.0)
			th = th + .0068 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(449334.0 * t + 188.0)
			th = th + .0079 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(826671.0 * t + 111.0)
			th = th + .0085 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1431597.0 * t + 315.0)
			th = th + .0100 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1303870.0 * t + 246.0)
			th = th + .0107 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(489205.0 * t + 142.0)
			th = th + .0110 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1443603.0 * t + 52.0)
			th = th + .0125 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(75870.0 * t + 41.0)
			th = th + .0154 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(513197.9 * t + 222.5)
			th = th + .0304 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(445267.1 * t + 27.9)
			th = th + .0347 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(441199.8 * t + 47.4)
			th = th + .0409 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(854535.2 * t + 148.2)
			th = th + .0458 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(1367733.1 * t + 280.7)
			th = th + .0533 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(377336.3 * t + 13.2)
			th = th + .0571 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(63863.5 * t + 124.2)
			th = th + .0588 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(966404.0 * t + 276.5)
			th = th + .1144 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(35999.05 * t + 87.53)
			th = th + .1851 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(954397.74 * t + 179.93)
			th = th + .2136 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(890534.22 * t + 145.7)
			th = th + .6583 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(413335.35 * t + 10.74)
			th = th + 1.2740 * math.cos(k * ang)
			ang = SELF:NORMALIZATION_ANGLE(477198.868 * t + 44.963)
			th = th + 6.2888 * math.cos(k * ang)

			ang = SELF:NORMALIZATION_ANGLE(481267.8809 * t)
			ang = SELF:NORMALIZATION_ANGLE(ang + 218.3162)
			th = SELF:NORMALIZATION_ANGLE(th + ang)

			return(th)
		end,
		YMDT2JD = function(SELF, year, month, day, hour, min, sec)
			if (month < 3.0) then
				year = year - 1.0
				month = month + 12.0
			end

			local jd = SELF:int(365.25 *year)
			jd = jd + SELF:int(year / 400.0)
			jd = jd - SELF:int(year / 100.0)
			jd = jd + SELF:int(30.59 * ( month - 2.0 ))
			jd = jd + 1721088
			jd = jd + day

			local t = sec / 3600.0
			t = t + min / 60.0
			t = t + hour
			t = t / 24.0

			return( jd + t)
		end,
		JD2YMDT = function(SELF, JD)
			local x0 = SELF:int(JD + 68570.0)
			local x1 = SELF:int(x0 / 36524.25)
			local x2 = x0 - SELF:int(36524.25 * x1 + 0.75)
			local x3 = SELF:int(( x2 + 1 ) / 365.2425)
			local x4 = x2 - SELF:int(365.25 * x3) + 31.0
			local x5 = SELF:int(SELF:int(x4) / 30.59)
			local x6 = SELF:int(SELF:int(x5) / 11.0)

			local TIME = {}
			TIME[2] = x4 - SELF:int(30.59 * x5)
			TIME[1] = x5 - 12 * x6 + 2
			TIME[0] = 100 * ( x1 - 49 ) + x3 + x6
			if TIME[1] == 2 and TIME[2] > 28 then
				if  TIME[0] % 100 == 0 and TIME[0] % 400 == 0 then
					TIME[2] = 29
				elseif TIME[0] % 4 == 0 then
					TIME[2] = 29
				else
					TIME[2] = 28
				end
			end

			local tm = 86400.0 * ( JD - SELF:int(JD) )
			TIME[3] = SELF:int(tm / 3600.0)
			TIME[4] = SELF:int((tm - 3600.0 * TIME[3]) / 60.0)
			TIME[5] = SELF:int(tm - 3600.0 * TIME[3] - 60 * TIME[4])

			return TIME
		end,

		int = function(SELF, i)
			i = tonumber(i)
			if i > 0 then
				return  math.floor(i)
			else
				return math.ceil(i)
			end
		end
	}

	return Q
end

return Qreki()