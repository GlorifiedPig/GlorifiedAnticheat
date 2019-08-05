local _CurTime = CurTime
local _FindMetaTable = FindMetaTable
local _Vector = Vector
local _math_random = math.random
local _math_randomseed = math.randomseed
local _math_sqrt = math.sqrt
local _timer_Simple = timer.Simple
local _type = type


if !gAC.config.ANTI_NOSPREAD_CHECKS then return end

_timer_Simple( 5, function()
    local entityMeta = _FindMetaTable( "Entity" )

    FBFunc = FBFunc or entityMeta.FireBullets

    function entityMeta:FireBullets( bulletInfo, suppressHostEvents )
        if( !bulletInfo || !bulletInfo.Num || bulletInfo.Num > 1 ) then
            return FBFunc( self, bulletInfo, suppressHostEvents )
        end

        local bulletSpread = bulletInfo.Spread
        if _type( bulletSpread ) == "Vector" then
            bulletInfo.Spread = vector_origin
            _math_randomseed( _CurTime() + _math_sqrt( bulletInfo.Dir.x ^ 2 * bulletInfo.Dir.y ^ 2 * bulletInfo.Dir.z ^ 2 ) )
            bulletInfo.Dir = bulletInfo.Dir + _Vector( bulletSpread.x * ( ( _math_random() * 2.5 ) - 1 ), bulletSpread.y * ( ( _math_random() * 2.5 ) - 1 ), bulletSpread.z * ( ( _math_random() * 2 ) - 1 ) )
        end

        return FBFunc(self, bulletInfo, suppressHostEvents )
    end
end )