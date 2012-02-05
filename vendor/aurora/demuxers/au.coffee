class AUDemuxer extends Demuxer
    Demuxer.register(AUDemuxer)
    
    @probe: (buffer) ->
        return buffer.peekString(0, 4) is '.snd'
        
    bps = [8, 8, 16, 24, 32, 32, 64]
    bps[26] = 8
        
    readChunk: ->
        if not @readHeader and @stream.available(24)
            if @stream.readString(4) isnt '.snd'
                return @emit 'error', 'Invalid AU file.'
                
            size = @stream.readUInt32()
            dataSize = @stream.readUInt32()
            encoding = @stream.readUInt32()
            
            @format = 
                formatID: 'lpcm'
                formatFlags: 0
                bitsPerChannel: bps[encoding - 1]
                sampleRate: @stream.readUInt32()
                channelsPerFrame: @stream.readUInt32()
            
            if not @format.bitsPerChannel?
                return @emit 'error', 'Unsupported encoding in AU file.'
            
            switch encoding
                when 1
                    @format.formatID = 'ulaw'
                when 6, 7
                    @format.formatFlags |= LPCMDecoder.FLOATING_POINT
                when 27
                    @format.formatID = 'alaw'
            
            if dataSize isnt 0xffffffff
                bytes = @format.bitsPerChannel / 8
                @emit 'duration', dataSize / bytes / @format.channelsPerFrame / @format.sampleRate * 1000 | 0
            
            @emit 'format', @format
            @readHeader = true
            
        if @readHeader
            while @stream.available(1)
                buf = @stream.readSingleBuffer(@stream.remainingBytes())
                @emit 'data', buf, @stream.remainingBytes() is 0