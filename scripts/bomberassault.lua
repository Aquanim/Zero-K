local bomb = piece('bomb');
local exhaustLeft = piece('exhaustLeft');
local exhaustRight = piece('exhaustRight');
local exhaustTop = piece('exhaustTop');
local hull = piece('hull');
local petalLeft = piece('petalLeft');
local petalRear = piece('petalRear');
local petalRight = piece('petalRight');
local turbineLeft = piece('turbineLeft');
local turbineRight = piece('turbineRight');
local turbineTop = piece('turbineTop');
local wingLeftFront = piece('wingLeftFront');
local wingLeftRear = piece('wingLeftRear');
local wingRightFront = piece('wingRightFront');
local wingRightRear = piece('wingRightRear');
local wingTopFront = piece('wingTopFront');
local wingTopRear = piece('wingTopRear');

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitHeading = Spring.GetUnitHeading
local spGetUnitVelocity = Spring.GetUnitVelocity

local smokePiece = {exhaustTop, exhaustRight, exhaustLeft}

local bombs = 1

include "bombers.lua"
include "constants.lua"

function script.Deactivate()
	StopSpin(turbineTop, y_axis, 0.5);
	StopSpin(turbineLeft, y_axis, 0.5);
	StopSpin(turbineRight, y_axis, 0.5);
end

function script.Activate()
	local px, py, pz = Spring.GetUnitPosition(unitID)
	Spring.PlaySoundFile("sounds/misc/blowtorch.wav", 10, px, py, pz)
	--Spin(turbineTop, y_axis, 8,2);
	--Spin(turbineLeft, y_axis, 8,2);
	--Spin(turbineRight, y_axis, -8,2);
end

function script.Create()
	StartThread(SmokeUnit, smokePiece)
end

function script.QueryWeapon(num)
	return bomb
end

function script.AimFromWeapon(num)
	return bomb
end

function script.AimWeapon(num, heading, pitch)
	return (Spring.GetUnitFuel(unitID) >= 1 and Spring.GetUnitRulesParam(unitID, "noammo") ~= 1)
end

function script.FireWeapon(num)
    if num == 1 then
	Sleep(66)
	Reload()
    end
end

local predictMult = 3

function script.BlockShot(num, targetID)
	return ((GetUnitValue(COB.CRASHING) == 1) or (Spring.GetUnitFuel(unitID) < 1) or (Spring.GetUnitRulesParam(unitID, "noammo") == 1))
end

function script.Killed(recentDamage, maxHealth)
	local severity = recentDamage/maxHealth
	if  severity <= .25  then
		Explode(turbineLeft, sfxFall + sfxSmoke  + sfxFire )
		Explode(turbineLeft, sfxFire)
		Explode(wingLeftFront, sfxFall + sfxSmoke  + sfxFire)
		Explode(wingLeftRear, sfxFall + sfxSmoke  + sfxFire)
		return 1
	elseif severity <= .50  then
		Explode(turbineLeft, sfxFall + sfxSmoke  + sfxFire )
		Explode(turbineLeft, sfxExplode)
		Explode(wingLeftFront, sfxFall + sfxSmoke  + sfxFire)
		Explode(wingLeftRear, sfxFall + sfxSmoke  + sfxFire)
		Explode(hull, sfxShatter)
		return 1
	elseif severity <= 0.75  then
		Explode(turbineLeft, sfxExplode + sfxSmoke  + sfxFire )
		Explode(turbineLeft, sfxExplode)
		Explode(wingLeftFront, sfxFall + sfxSmoke  + sfxFire)
		Explode(wingLeftRear, sfxFall + sfxSmoke  + sfxFire)
		Explode(hull, sfxShatter )
		return 1
	else
		Explode(turbineLeft, sfxExplode + sfxSmoke  + sfxFire )
		Explode(turbineLeft, sfxExplode)
		Explode(wingLeftFront, sfxExplode + sfxSmoke  + sfxFire)
		Explode(wingLeftRear, sfxExplode + sfxSmoke  + sfxFire)
		Explode(turbineRight, sfxExplode + sfxSmoke  + sfxFire )
		Explode(turbineRight, sfxExplode)
		Explode(wingRightFront, sfxExplode + sfxSmoke  + sfxFire)
		Explode(wingRightRear, sfxExplode + sfxSmoke  + sfxFire)
		Explode(turbineTop, sfxExplode)
		Explode(wingTopFront, sfxExplode + sfxSmoke  + sfxFire)
		Explode(wingTopRear, sfxExplode + sfxSmoke  + sfxFire)
		
		Explode(hull, sfxShatter )
		return 2
	end
end
