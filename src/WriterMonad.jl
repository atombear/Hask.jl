module WriterMonad

import Base: *

export LogString, Writer, unit, bind, log

abstract type Log end

struct LogString <: Log
    s::String
end

*(a::LogString, b::LogString) :: LogString = LogString(a.s * "\n" * b.s)

struct EmptyLog <: Log
end

*(a::EmptyLog, b::LogString) :: LogString = b
*(a::LogString, b::EmptyLog) :: LogString = a


struct Writer{T}
    runWriter::Tuple{Log, T}
    Writer(runWriter) = new{typeof(runWriter[2])}(runWriter)
end

function unit(val) :: Writer{typeof(val)}
    return Writer((EmptyLog(), val))
end

function bind(wa::Writer, k) :: Writer
    loga, vala = wa.runWriter
    logb, valb = k(vala).runWriter
    return Writer((loga * logb, valb))
end

function log(s::String) :: Writer{Nothing}
    return Writer((LogString(s), nothing))
end

end