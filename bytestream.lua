local bit32 = require"bit32"

local bytestream = {
    _bytes = {},
    _currentIndex = {current = 1, last = 1},
    _restorePoint = nil,
    settings = {
        intSize = 4,
        tSize = 4
    }
}

local function getBitSize(i)
    return 8 * i
end

function bytestream.open(bytes)
    bytestream._bytes = bytes
end

function bytestream.backupdData()
    bytestream._restorePoint = {
        _currentIndex = bytestream._currentIndex,
        _restorePoint = bytestream._restorePoint,
        _bytes = bytestream._bytes,
        settings = bytestream.settings
    }
end

function bytestream.rollback()
    bytestream._bytes = bytestream._restorePoint._bytes
    bytestream._currentIndex = bytestream._restorePoint._currentIndex
    bytestream.settings = bytestream._restorePoint.settings
    bytestream._restorePoint = bytestream._restorePoint._restorePoint
end

function bytestream.incIndex(amt)
    bytestream._currentIndex.last = bytestream._currentIndex.current
    bytestream._currentIndex.current = bytestream._currentIndex.current + amt
end

function bytestream.setIndex(idx)
    bytestream._currentIndex.last = bytestream._currentIndex.current
    bytestream._currentIndex.current = idx
end

function bytestream.readBytes(length)
    local bytes = {}
    for i = 1, length do
        bytes[i] = bytestream._bytes[bytestream._currentIndex.current]
        bytestream.incIndex(1)
    end
    return bytes
end

function bytestream.readString(len)
    local str = ''
    for i = 1, len do
        str = str .. string.char(bytestream.readBytes(1)[1])
    end
    return str
end

function bytestream.readInt16LE()
    local b1 = bytestream.readBytes(1)[1]
    local b2 = bytestream.readBytes(1)[1]
    return bit32.bor(bit32.lshift(b1, getBitSize(1)), b2)
end

function bytestream.readInt16BE()
    local b1 = bytestream.readBytes(1)[1]
    local b2 = bytestream.readBytes(1)[1]
    return bit32.bor(bit32.lshift(b2, getBitSize(1)), b1)
end

function bytestream.readInt32LE()
    local b1, b2, b3, b4 = bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], bytestream.readBytes(1)[1]
    return bit32.bor(
        b4,
        bit32.lshift(b3, getBitSize(1)),
        bit32.lshift(b2, getBitSize(2)),
        bit32.lshift(b1, getBitSize(3))
    )
end

function bytestream.readInt32BE()
    local b1, b2, b3, b4 = bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], bytestream.readBytes(1)[1]
    return bit32.bor(
        b1,
        bit32.lshift(b2, getBitSize(1)),
        bit32.lshift(b3, getBitSize(2)),
        bit32.lshift(b4, getBitSize(3))
    )
end

function bytestream.readInt64LE()
    local b1, b2, b3, b4, b5, b6, b7, b8 = bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], 
        bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], 
        bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], 
        bytestream.readBytes(1)[1], bytestream.readBytes(1)[1]

    return bit32.bor(
        b8,
        bit32.lshift(b7, getBitSize(1)),
        bit32.lshift(b6, getBitSize(2)),
        bit32.lshift(b5, getBitSize(3)),
        bit32.lshift(b4, getBitSize(4)),
        bit32.lshift(b3, getBitSize(5)),
        bit32.lshift(b2, getBitSize(6)),
        bit32.lshift(b1, getBitSize(7))
    )
end

function bytestream.readInt64BE()
    local b1, b2, b3, b4, b5, b6, b7, b8 = bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], 
        bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], 
        bytestream.readBytes(1)[1], bytestream.readBytes(1)[1], 
        bytestream.readBytes(1)[1], bytestream.readBytes(1)[1]

    return bit32.bor(
        b1,
        bit32.lshift(b2, getBitSize(1)),
        bit32.lshift(b3, getBitSize(2)),
        bit32.lshift(b4, getBitSize(3)),
        bit32.lshift(b5, getBitSize(4)),
        bit32.lshift(b6, getBitSize(5)),
        bit32.lshift(b7, getBitSize(6)),
        bit32.lshift(b8, getBitSize(7))
    )
end

function bytestream.writeBytes(...)
    local bytes = {...}
    for i = 1, #bytes do
        bytestream._bytes[bytestream._currentIndex.current] = bytes[i]
        bytestream.incIndex(1)
    end
end

function bytestream.writeString(str)
    for i = 1, #str do
        bytestream.writeBytes(string.byte(string.sub(str, i, i)))
    end
end

function bytestream.writeInt16LE(num)
    bytestream.writeBytes(bit32.band(bit32.rshift(num, getBitSize(1)), 0xFF))
    bytestream.writeBytes(bit32.band(num, 0xFF))
end

function bytestream.writeInt16BE(num)
    bytestream.writeBytes(bit32.band(num, 0xFF))
    bytestream.writeBytes(bit32.band(bit32.rshift(num, getBitSize(1)), 0xFF))
end

function bytestream.writeInt32LE(num)
    local b1 = bit32.band(num, 0xFF)
    local b2 = bit32.band(bit32.rshift(num, getBitSize(1)), 0xFF)
    local b3 = bit32.band(bit32.rshift(num, getBitSize(2)), 0xFF)
    local b4 = bit32.band(bit32.rshift(num, getBitSize(3)), 0xFF)
    bytestream.writeBytes(b4, b3, b2, b1)
end

function bytestream.writeInt32BE(num)
    local b1 = bit32.band(num, 0xFF)
    local b2 = bit32.band(bit32.rshift(num, getBitSize(1)), 0xFF)
    local b3 = bit32.band(bit32.rshift(num, getBitSize(2)), 0xFF)
    local b4 = bit32.band(bit32.rshift(num, getBitSize(3)), 0xFF)
    bytestream.writeBytes(b1, b2, b3, b4)
end

function bytestream.writeInt64LE(num)
    local b1 = bit32.band(num, 0xFF)
    local b2 = bit32.band(bit32.rshift(num, getBitSize(1)), 0xFF)
    local b3 = bit32.band(bit32.rshift(num, getBitSize(2)), 0xFF)
    local b4 = bit32.band(bit32.rshift(num, getBitSize(3)), 0xFF)
    local b5 = bit32.band(bit32.rshift(num, getBitSize(4)), 0xFF)
    local b6 = bit32.band(bit32.rshift(num, getBitSize(5)), 0xFF)
    local b7 = bit32.band(bit32.rshift(num, getBitSize(6)), 0xFF)
    local b8 = bit32.band(bit32.rshift(num, getBitSize(7)), 0xFF)
    bytestream.writeBytes(b1, b2, b3, b4, b5, b6, b7, b8)
end

function bytestream.writeInt64BE(num)
    local b1 = bit32.band(num, 0xFF)
    local b2 = bit32.band(bit32.rshift(num, getBitSize(1)), 0xFF)
    local b3 = bit32.band(bit32.rshift(num, getBitSize(2)), 0xFF)
    local b4 = bit32.band(bit32.rshift(num, getBitSize(3)), 0xFF)
    local b5 = bit32.band(bit32.rshift(num, getBitSize(4)), 0xFF)
    local b6 = bit32.band(bit32.rshift(num, getBitSize(5)), 0xFF)
    local b7 = bit32.band(bit32.rshift(num, getBitSize(6)), 0xFF)
    local b8 = bit32.band(bit32.rshift(num, getBitSize(7)), 0xFF)
    bytestream.writeBytes(b8, b7, b6, b5, b4, b3, b2, b1)
end

function bytestream.patchBytes(idx, ...)
    local bytes = {...}
    for i = 0, #bytes-1 do
        bytestream._bytes[idx+i] = bytes[i+1]
    end
end

function bytestream.close()
    bytestream._bytes = {}
    bytestream._currentIndex = {current = 1, last = 1}
    bytestream._restorePoint = {}
    bytestream.settings = {
        intSize = 4,
        tSize = 4
    }
end

function bytestream._dump()
    local dump = ''
    for i = 1, #bytestream._bytes do
        dump = dump .. tostring(tonumber(bytestream._bytes[i])) .. ' '
    end
    print(dump)
end

return bytestream
