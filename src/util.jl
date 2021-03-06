# Helpful utility functions

# Set the value of a field of a pointer
# Equivalent to s->name = value
@inline function av_setfield(s::Ptr{T}, name::Symbol, value) where T
    field_pos = Base.fieldindex(T, name)
    byteoffset = fieldoffset(T, field_pos)
    S = fieldtype(T, name)

    p = convert(Ptr{S}, s + byteoffset)
    unsafe_store!(p, convert(S, value))
end

function av_pointer_to_field(s::Ptr{T}, name::Symbol) where T
    field_pos = Base.fieldindex(T, name)
    byteoffset = fieldoffset(T, field_pos)
    return s + byteoffset
end

av_pointer_to_field(s::Array, name::Symbol) = av_pointer_to_field(pointer(s), name)

function collectexecoutput(exec::Cmd)
    out = Pipe(); err = Pipe()
    p = Base.open(pipeline(ignorestatus(exec), stdout=out, stderr=err))
    close(out.in); close(err.in)
    err_s = readlines(err); out_s = readlines(out)
    return (length(out_s) > length(err_s)) ? out_s : err_s
end

"""
loglevel!(loglevel::Integer)

Set FFMPEG log level. Options are:
- `VideoIO.AVUtil.AV_LOG_QUIET`
- `VideoIO.AVUtil.AV_LOG_PANIC`
- `VideoIO.AVUtil.AV_LOG_FATAL`
- `VideoIO.AVUtil.AV_LOG_ERROR`
- `VideoIO.AVUtil.AV_LOG_WARNING`
- `VideoIO.AVUtil.AV_LOG_INFO`
- `VideoIO.AVUtil.AV_LOG_VERBOSE`
- `VideoIO.AVUtil.AV_LOG_DEBUG`
- `VideoIO.AVUtil.AV_LOG_TRACE`
"""
function loglevel!(level::Integer)
    av_log_set_level(level)
    return loglevel()
end

"""
loglevel() -> String

Get FFMPEG log level as a variable name string.
"""
function loglevel()
    current_level = av_log_get_level()
    level_strings = [
        "VideoIO.AVUtil.AV_LOG_QUIET",
        "VideoIO.AVUtil.AV_LOG_PANIC",
        "VideoIO.AVUtil.AV_LOG_FATAL",
        "VideoIO.AVUtil.AV_LOG_ERROR",
        "VideoIO.AVUtil.AV_LOG_WARNING",
        "VideoIO.AVUtil.AV_LOG_INFO",
        "VideoIO.AVUtil.AV_LOG_VERBOSE",
        "VideoIO.AVUtil.AV_LOG_DEBUG",
        "VideoIO.AVUtil.AV_LOG_TRACE"
    ]
    level_values = [
        VideoIO.AVUtil.AV_LOG_QUIET,
        VideoIO.AVUtil.AV_LOG_PANIC,
        VideoIO.AVUtil.AV_LOG_FATAL,
        VideoIO.AVUtil.AV_LOG_ERROR,
        VideoIO.AVUtil.AV_LOG_WARNING,
        VideoIO.AVUtil.AV_LOG_INFO,
        VideoIO.AVUtil.AV_LOG_VERBOSE,
        VideoIO.AVUtil.AV_LOG_DEBUG,
        VideoIO.AVUtil.AV_LOG_TRACE
    ]
    i = findfirst(level_values.==current_level)
    if i > 0
        return level_strings[i]
    else
        return "Unknown log level: $current_level"
    end
end

# a convenience function for getting the aspect ratio
function aspect_ratio(f)
    if iszero(f.aspect_ratio) || isnan(f.aspect_ratio) || isinf(f.aspect_ratio) # if the stored aspect ratio is nonsense then we default to one. OBS, this might still be wrong for some videos and an unnecessary test for most
        1//1
    else
        f.aspect_ratio
    end
end
