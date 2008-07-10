--[[-------------------------------------------------------------------------
  Copyright (c) 2007, Trond A Ekseth, Chris Bannister
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
      * Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials provided
        with the distribution.
      * Neither the name of Yaapa nor the names of its contributors may
        be used to endorse or promote products derived from this
        software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------]]

local _G = getfenv(0)
local string_format = string.format
local math_floor = math.floor
local math_exp = math.exp

local GetArenaTeam = GetArenaTeam
local GetArenaCurrency = GetArenaCurrency
local PVPFrameArenaPoints = PVPFrameArenaPoints

local print = function(str) ChatFrame1:AddMessage("|cff33ff99Scapegoat:|r "..tostring(str)) end

-- Completly non-evil, but at least we don't get the overhead of hooksecurefunc.
local dummy = function() end
for i=1, 3 do
	local fn = "PVPTeam"..i

	_G[fn.."DataRating"].SetText = dummy
	_G[fn.."DataRatingLabel"].SetText = dummy
end

local SetText = PVPFrameArenaPoints.SetText
PVPFrameArenaPoints.SetText = dummy

local points
local getPoints = function(rating, size)
	if(rating <= 1500) then
		points = (.22 * rating) + 14

		if(points < 0) then points = 0 end
	else
		points = (1511.26 / (1 + (1639.28*(2.71828^(-0.00412*rating)))))
	end

	if(size == 2) then
		return math_floor(points * .76)
	elseif(size == 3) then
		return math_floor(points * .88)
	end

	return math_floor(points)
end

local fn, id, teamSize, teamRating, teamPlayed, playerPlayed, points, lframe, _
local mikoreimu = function()
	local ep = 0

	for i=1,3 do
		fn = "PVPTeam"..i
		id = _G[fn]:GetID()

		if(id > 0) then
			_, teamSize, teamRating, teamPlayed, _, _, _, playerPlayed = GetArenaTeam(id)
			rframe = _G[fn.."DataRating"]

			if(teamPlayed >= 10 and (playerPlayed / teamPlayed) >= .3) then
				points = getPoints(teamRating, teamSize)
				lframe = _G[fn.."DataRatingLabel"]

				rframe:SetWidth(65)
				lframe:ClearAllPoints()
				lframe:SetPoint("LEFT", _G[fn.."DataName"], "RIGHT", -30, 0)

				SetText(rframe, string_format("%d (%d)", teamRating, points))
				ep = (ep and points > ep and points) or ep
			else
				SetText(rframe, teamRating)
			end
		else
			break
		end
	end

	points = GetArenaCurrency()
	if(ep > 0) then
		SetText(PVPFrameArenaPoints, string_format("%d (%d)", points, points+ep))
	else
		SetText(PVPFrameArenaPoints, points)
	end
end

--[[
-- Za Warudo!
--]]

local yaapa = CreateFrame"Frame"

yaapa.mikoreimu = mikoreimu
yaapa.getPoints = getPoints

yaapa.ARENA_TEAM_UPDATE = mikoreimu
yaapa.PLAYER_ENTERING_WORLD = mikoreimu

yaapa:SetScript("OnEvent", function(self, event, ...) self[event](...) end)

yaapa:RegisterEvent"ARENA_TEAM_UPDATE"
yaapa:RegisterEvent"PLAYER_ENTERING_WORLD"

local team_size = {
	[2] = "2v2",
	[3] = "3v3",
	[5] = "5v5"
}

local Slasher = function(s)
	local rating = tonumber(s)

	if(rating and rating > 0) then
		local points = getPoints(rating)
		local v2, v3 = math_floor(points * .76), math_floor(points * .88)

		print(string.format("2v2: %d | 3v3: %d | 5v5: %d", v2, v3, points))
	else
		local t = {}
		for i = 1, 3 do
			if GetArenaTeam(i) then
				local _, teamSize, teamRating, teamPlayed, _, _, _, playerPlayed = GetArenaTeam(i)
				local played = (teamPlayed >= 10 and (playerPlayed / teamPlayed) >= .3)
				local points = getPoints(teamRating, teamSize)
				local size = team_size[teamSize]
				table.insert(t, i, {["size"] = teamSize, ["rating"] = teamRating, ["points"] = points, ["eligable"] = played})
			end
		end
		table.sort(t, function(a, b)
			return a.points > b.points
		end)
		for k, v in ipairs(t) do
			local size, rating, points, eligable = v.size, v.rating, v.points, v.eligable
			local str
			if eligable then
				str = "%s: %d (%d)"
			else
				str = "%s: %d (%d) *"
			end
			print(string.format(str, size, points, rating))
		end
	end
end

_G.SlashCmdList["YAAPA_ARENA"] = Slasher
_G.SLASH_YAAPA_ARENA1 = "/arena"
