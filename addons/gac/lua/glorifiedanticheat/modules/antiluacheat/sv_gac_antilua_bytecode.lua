--[[
	Common anticheats use source identification to detect invalids of a lua file.
	Using bytecode we can precisely pinpoint what is supposed to be in a lua file.

	This works like string.find but on a higher level of sub'ing and identification.
	With the use of finding certain values in a function dump we can find function information
	similar to debug.getinfo but only using the dumps to search through.

	After all string.dump was originally intended to get the dump information of lua which
	can be ran again in it's dump state as normal lua code.
]]

local _bit_band = bit.band
local _bit_rshift = bit.rshift
local _jit_util_funcbc = jit.util.funcbc
local _table_concat = table.concat
local _string_char = string.char
local _isstring = isstring
local _tonumber = tonumber
local _util_CRC = util.CRC

ByteCode = {}

-- Hex codes of dump lua environment. (operands)
-- https://www.lua.org/manual/5.1/manual.html & https://www.lua.org/source/5.3/lopcodes.h.html
local opcodeMap =
{
	[0x46] = 0x51, -- RET -> LOOP
	[0x47] = 0x51, -- RET0 -> LOOP
	[0x48] = 0x51, -- RET1 -> LOOP
	[0x49] = 0x49, -- FORI -> FORI
	[0x4A] = 0x49, -- JFORI -> FORI
	[0x4B] = 0x4B, -- FORL -> FORL
	[0x4C] = 0x4B, -- IFORL -> FORL
	[0x4D] = 0x4B, -- JFORL -> FORL
	[0x4E] = 0x4E, -- ITERL -> ITERL
	[0x4F] = 0x4E, -- IITERL -> ITERL
	[0x50] = 0x4E, -- JITERL -> ITERL
	[0x51] = 0x51, -- LOOP -> LOOP
	[0x52] = 0x51, -- ILOOP -> LOOP
	[0x53] = 0x51, -- JLOOP -> LOOP
}

-- Hex codes of dump lua environment. (opcode)
-- https://www.lua.org/source/5.3/lopcodes.h.html
local opcodeMap2 =
{
	[0x44] = 0x54, -- ISNEXT -> JMP
	[0x42] = 0x41, -- ITERN -> ITERC
}

--[[
	Uses the given function to get bytecode information.
	uses the already provided jit.util.funcinfo information's bytecode instructions
	to form a unique identifier for the function.
]]

function ByteCode.FunctionToHash(func, funcinfo)
    local data = {}
    for i = 1, funcinfo.bytecodes - 1 do
        local bytecode = _jit_util_funcbc (func, i)
        local byte = _bit_band (bytecode, 0xFF)
        if opcodeMap[byte] then
            bytecode = opcodeMap[byte]
        end
        if opcodeMap2[byte] then
            bytecode = bytecode - byte
            bytecode = bytecode + opcodeMap2[byte]
        end
        data [#data + 1] = _string_char (
            _bit_band (bytecode, 0xFF),
            _bit_band (_bit_rshift(bytecode,  8), 0xFF),
            _bit_band (_bit_rshift(bytecode, 16), 0xFF),
            _bit_band (_bit_rshift(bytecode, 24), 0xFF)
        )
    end
    return _tonumber(_util_CRC(_table_concat(data)))
end

--[[
	Skims through function dump information and returns 
	the dump information of that function (like string.dump, 
	except using it on functions and not an entire execution)
]]

function ByteCode.ByteCodeDumpToHash(inBuffer, instructionCount)
	if _isstring (inBuffer) then
		inBuffer = gAC.StringInBuffer(inBuffer)
	end
	
	local outBuffer = gAC.StringOutBuffer()
	for i = 1, instructionCount do
		local instruction = inBuffer:UInt32()
		local opcode = _bit_band(instruction, 0xFF)
		
		if opcodeMap[opcode] then
			-- Remap operands
			instruction = opcodeMap [opcode]
		end
		
		if opcodeMap2[opcode] then
			-- Remap opcode
			instruction = instruction - opcode
			instruction = instruction + opcodeMap2[opcode]
		end
		
		outBuffer:UInt32(instruction)
	end
	
	return _tonumber(_util_CRC(outBuffer:GetString()))
end

--[[
	Skims through function dump information and returns line definitions & etc (kind of line debug.getinfo but using dumps)
]]

function ByteCode.GetFuncInformation(inBuffer, functionInformation)
	functionInformation = functionInformation or {}

	if _isstring (inBuffer) then
		inBuffer = gAC.StringInBuffer (inBuffer)
	end
	
	-- this is like the exact iteration of data that comes out of debug.getinfo & jit.util.funcinfo
	inBuffer:UInt8() -- Flags
	inBuffer:UInt8() -- Fixed parameter count
	inBuffer:UInt8() -- Frame size
	inBuffer:UInt8() -- Upvalue count
	inBuffer:ULEB128() -- Garbage collected constant count
	inBuffer:ULEB128() -- Numeric constant count
	local instructionCount = inBuffer:ULEB128() -- Instruction count (the bytecode outcome on jit.util.funcinfo)
	inBuffer:ULEB128()
	
	functionInformation.linedefined = inBuffer:ULEB128()
	local lineCount = inBuffer:ULEB128()
	functionInformation.lastlinedefined = functionInformation.linedefined + lineCount
	functionInformation.proto = ByteCode.ByteCodeDumpToHash(inBuffer, instructionCount)
	
	return functionInformation
end

--[[
	Skims through string.dump information towards an list of function dump information.
]]

function ByteCode.DumpToFunctionList(dump)
	local inBuffer = gAC.StringInBuffer (dump)
	
	-- Header, file execution information (signatures > flags > source)
	inBuffer:Bytes(4)
	inBuffer:UInt8()
	inBuffer:Bytes(inBuffer:ULEB128())
	
	-- Functions, their execution information
	local functionInformationArray = {}
	local functionDataLength = inBuffer:ULEB128()
	while functionDataLength ~= 0 do
		local functionData = inBuffer:Bytes(functionDataLength)
		local functionInformation = ByteCode.GetFuncInformation(functionData)
		functionInformationArray[#functionInformationArray + 1] = functionInformation
		functionDataLength = inBuffer:ULEB128()
	end
	
	return functionInformationArray
end