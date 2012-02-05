class LPCMDecoder extends Decoder
    Decoder.register('lpcm', LPCMDecoder)
    
    @FLOATING_POINT = 1 << 0
    @LITTLE_ENDIAN  = 1 << 1
    {FLOATING_POINT, LITTLE_ENDIAN} = LPCMDecoder
    
    constructor: ->
        super
        
        flags = @format.formatFlags or 0
        @floatingPoint = Boolean(flags & FLOATING_POINT)
        @littleEndian = Boolean(flags & LITTLE_ENDIAN)
    
    readChunk: =>
        {stream, littleEndian} = this
        chunkSize = Math.min(4096, @stream.remainingBytes())
        samples = chunkSize / (@format.bitsPerChannel / 8) >> 0
        
        if chunkSize is 0
            return @once 'available', @readChunk
        
        if @floatingPoint
            switch @format.bitsPerChannel
                when 32
                    output = new Float32Array(samples)
                    for i in [0...samples] by 1
                        output[i] = stream.readFloat32(littleEndian)
                        
                when 64
                    output = new Float64Array(samples)
                    for i in [0...samples] by 1
                        output[i] = stream.readFloat64(littleEndian)
                        
                else
                    return @emit 'error', 'Unsupported bit depth.'
            
        else
            switch @format.bitsPerChannel
                when 8
                    output = new Int8Array(samples)
                    for i in [0...samples] by 1
                        output[i] = stream.readInt8()
                
                when 16
                    output = new Int16Array(samples)
                    for i in [0...samples] by 1
                        output[i] = stream.readInt16(littleEndian)
                    
                when 24
                    output = new Int32Array(samples)
                    for i in [0...samples] by 1
                        output[i] = stream.readInt24(littleEndian)
                
                when 32
                    output = new Int32Array(samples)
                    for i in [0...samples] by 1
                        output[i] = stream.readInt32(littleEndian)
                    
                else
                    return @emit 'error', 'Unsupported bit depth.'
        
        @emit 'data', output