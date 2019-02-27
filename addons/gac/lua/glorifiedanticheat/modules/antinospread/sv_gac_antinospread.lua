
if !gAC.config.ANTI_NOSPREAD_CHECKS then return end

local entityMeta = FindMetaTable( "Entity" )
entityMeta.OldFireBullets = entityMeta.OldFireBullets or entityMeta.FireBullets

function entityMeta:FireBullets( bullet, suppress )
    local spread = bullet.Spread
    
	if type( spread ) == "Vector" then
		bullet.Spread = vector_origin

        print(bullet.Dir.x)
        if( bullet.Dir.x <= 0.01 && bullet.Dir.x >= -0.01 ) then
            bullet.Dir = bullet.Dir + Vector( math.Rand( 0.01, 0.1 ), bullet.Dir.y, bullet.Dir.z )
        end
        if( bullet.Dir.y <= 0.01 && bullet.Dir.y >= -0.01 ) then
            bullet.Dir = bullet.Dir + Vector( bullet.Dir.x, math.Rand( 0.01, 0.1 ), bullet.Dir.z )
        end
        if( bullet.Dir.z <= 0.01 && bullet.Dir.z >= -0.01 ) then
            bullet.Dir = bullet.Dir + Vector( bullet.Dir.x, bullet.Dir.y, math.Rand( 0.01, 0.1 ) )
        end
	end

	self:OldFireBullets( bullet, suppress )
end