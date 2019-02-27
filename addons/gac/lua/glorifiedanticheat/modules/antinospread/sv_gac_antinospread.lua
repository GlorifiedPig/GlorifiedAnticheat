
if !gAC.config.ANTI_NOSPREAD_CHECKS then return end

timer.Simple( 5, function()
    local entityMeta = FindMetaTable( "Entity" )

    FBFunc = FBFunc or entityMeta.FireBullets

    function entityMeta:FireBullets( bulletInfo, suppressHostEvents )
        if( !bulletInfo || !bulletInfo.Num || bulletInfo.Num > 1 ) then
            return FBFunc( self, bulletInfo, suppressHostEvents )
        end

        local bulletSpread = bulletInfo.Spread
        if type( bulletSpread ) == "Vector" then
            bulletInfo.Spread = vector_origin
            math.randomseed( CurTime() + math.sqrt( bulletInfo.Dir.x ^ 2 * bulletInfo.Dir.y ^ 2 * bulletInfo.Dir.z ^ 2 ) )
            bulletInfo.Dir = bulletInfo.Dir + Vector( bulletSpread.x * ( ( math.random() * 2.5 ) - 1 ), bulletSpread.y * ( ( math.random() * 2.5 ) - 1 ), bulletSpread.z * ( ( math.random() * 2 ) - 1 ) )
        end

        return FBFunc(self, bulletInfo, suppressHostEvents )
    end
end )