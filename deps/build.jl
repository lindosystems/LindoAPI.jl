#=

 File: LindoAPI.jl
 Brief: This file is ran when the LindoAPI is built

 Authors: Pkg generate, James Haas, Mustafa Atlihan

 Bugs:

=#
using Libdl


@info "Working directory ... $(dirname(@__FILE__))\n"



const _DEPS_FILE = joinpath(dirname(@__FILE__), "deps.jl")
if isfile(_DEPS_FILE)
    rm(_DEPS_FILE)
end

function write_depsfile(liblindo, LS_MAJOR, LS_MINOR)
    try 
        open(_DEPS_FILE, "w") do f
            println(f, "const liblindo = \"$(escape_string(liblindo))\"")
            println(f, "const LS_MAJOR = $(LS_MAJOR)")
            println(f, "const LS_MINOR = $(LS_MINOR)")
    end
        println("Dependency file written successfully.")
    catch error
        println("Error writing dependency file: $error")
    end

end

is_64bits = Sys.WORD_SIZE == 64

function get_error_message_if_not_found()
    return """
    Unable to install LindoAPI.jl

    """
end

#=

 Function ls_get_version:
 Breif: Gets the version numbers for the Windows Lindo API.

 Param filename: The file is 'PATH/include/lsversion.sh'

 Return LS_MAJOR, LS_MINOR: API Version Numbers.

=#
function ls_get_version(filename)
    
    if !isfile(filename)
        LS_MAJOR = 0
        LS_MINOR = 0
    else
        open(filename, "r")
        lines = readlines(filename)
        LS_MAJOR = rsplit(lines[1],"=")[2]
        LS_MINOR= rsplit(lines[2],"=")[2]
    end

    return LS_MAJOR, LS_MINOR
end

#=

 Function platform:
 Brief: Name of the LINDO API bin/ subdirectory for the operating system
        and processor this Julia runs on. Sys.ARCH is Julia's own
        architecture, so an x86_64 Julia running under emulation (Rosetta 2,
        Windows on ARM) gets the x86_64 library it is able to load.

 Return: "win64", "win64arm", "win32", "linux64", "linux64arm", "linux32",
         "osx64x86", "osx64arm", or "" if LINDO API has no build for it.

=#
function platform()
    if Sys.iswindows()
        Sys.ARCH == :x86_64  && return "win64"
        Sys.ARCH == :aarch64 && return "win64arm"
        Sys.ARCH == :i686    && return "win32"
    elseif Sys.islinux()
        Sys.ARCH == :x86_64  && return "linux64"
        Sys.ARCH == :aarch64 && return "linux64arm"
        Sys.ARCH == :i686    && return "linux32"
    elseif Sys.isapple()
        Sys.ARCH == :x86_64  && return "osx64x86"
        Sys.ARCH == :aarch64 && return "osx64arm"
    end
    return ""
end

#=

 Function library:
 Breif: Gets Full path to the Lindo API which depends on the Operating system
        and the processor.

 Return liblindo: path to the Lindo API

=#
function library()
    liblindo = ""
    if haskey(ENV, "LINDOAPI_HOME")
        PATH = ENV["LINDOAPI_HOME"]
    else
        PATH = ""
            @warn "Environment variable LINDOAPI_HOME is empty.
                   Please set LINDOAPI_HOME to the root of your LINDO API directory and reinstall this package. "
    end
    LS_MAJOR, LS_MINOR = ls_get_version(joinpath(PATH, "include/lsversion.sh"))
    PLATFORM = platform()
    if LS_MAJOR == 0 && LS_MINOR == 0
        liblindo = ""
    elseif PLATFORM == ""
        error("LINDO API is not available for $(Sys.KERNEL) on $(Sys.ARCH)")
    elseif Sys.iswindows()
        # lindo64_<major>_<minor> on win64 and win64arm, lindo<major>_<minor> on win32
        if is_64bits
            liblindo = joinpath(PATH,"bin/"*PLATFORM*"/lindo64_"*LS_MAJOR*"_"*LS_MINOR)
        else
            liblindo = joinpath(PATH,"bin/"*PLATFORM*"/lindo"*LS_MAJOR*"_"*LS_MINOR)
        end
    else
        if is_64bits
            liblindo = joinpath(PATH,"bin/"*PLATFORM*"/liblindo64")
        else
            liblindo = joinpath(PATH,"bin/"*PLATFORM*"/liblindo")
        end
    end
    return liblindo, LS_MAJOR, LS_MINOR
end

#=

 Function check_library:
 Breif: Loads the API as test to see if the path liblindo from
        library() is valid.

 Return Bool: False if Libray will not open
              True otherwise.

=#
function check_library(liblindo)
    if Libdl.dlopen_e(liblindo) == C_NULL
        return false
    else
        return true
    end
end

#=

 Function try_installation:
 Breif: This is the function that is clled by the the build.jl script
        to install the package. It calls the above function and throws error
        if not successful.

=#
function try_installation()
    liblindo, LS_MAJOR, LS_MINOR = library()
    if check_library(liblindo)
        @info "Found API location `$(liblindo)`"
    else
        @warn "Lindo API not found at `$(liblindo)`. Please install the Lindo API and reinstall this package."
    end
    write_depsfile(liblindo, LS_MAJOR, LS_MINOR)
end




try_installation()
