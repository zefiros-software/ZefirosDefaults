--[[ @cond ___LICENSE___
-- Copyright (c) 2017 Zefiros Software.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @endcond
--]]

zefiros = {
    name = nil
}

function zefiros.testDefinition(name)

    configurations { "Test" }

    project(name)

    kind "ConsoleApp"
    files "test*.cpp"

    zpm.uses "Zefiros-Software/GoogleTest"

    workspace()
end

function zefiros.setDefaults( name, options )

    zefiros.name = name
    local licenseheader = name .. "/" .. name .. ".licenseheader"    

    if not options then
        options = {}
    end

    if options.mayLink == nil then
        options.mayLink = true
    end

    local config = { "Release", "Debug", "OptDebug" }
    local lconf = {}
    if options.headerOnly ~= nil and options.headerOnly then

        for _, c in ipairs( config ) do
            lconf = zpm.util.concat( lconf, {string.format( "HeaderOnly%s", c )} )
        end
    end
    config = zpm.util.concat( config, lconf )
    configurations( config )

    platforms { "x86_64", "x86" }
    startproject( name .. "-test" )
	location( name )
	objdir "bin/obj/"

	vectorextensions "SSE2"
	warnings "Extra"

    filter "system:not macosx"
        linkgroups "On"

    filter "system:not windows"
        configurations "Coverage"
    
    filter "platforms:x86"
        targetdir "bin/x86/"
        debugdir "bin/x86/"
        architecture "x86"
    
    filter "platforms:x86_64"
        targetdir "bin/x86_64/"
        debugdir "bin/x86_64/"
        architecture "x86_64"
        
    filter "*Debug"
        targetsuffix "d"
        defines "DEBUG"
        symbols "On"
        optimize "Off"
        
    filter "*OptDebug"
        targetsuffix "od"
        flags "LinkTimeOptimization"
        optimize "Speed"

    filter "*Release"        
        optimize "Speed"
        defines "NDEBUG"

    filter { "*Release", "system:not linux" }
        flags "LinkTimeOptimization"

    filter { "*OptDebug", "system:not linux" }
        flags "LinkTimeOptimization"
        
    filter "Coverage" 
        targetsuffix "cd"
        links "gcov"
        buildoptions "-coverage" 
        symbols "On"
        optimize "Off"
    
        objdir "!."
        targetdir "."
        
    filter "not HeaderOnly*"
        defines( options.noHeaderOnlySwitch )

    filter {}

    if os.isfile( licenseheader ) and os.isdir( "test" ) then
        os.copyfile( licenseheader, path.join("test", name .. ".licenseheader") )
    end 
			
	project( name .. "-test" )
				
		kind "ConsoleApp"		
		location "test/"
        
        zpm.uses {
			"Zefiros-Software/GoogleTest"
		}
		
		includedirs {			
			name .. "/include/",
			"test/"
			}	
		
		files { 
			"test/**.h",
			"test/**.cpp",
            "test/**.licenseheader"
			}

        excludes { 
            "test/extern/**",
            "test/assets/**"
         }
                     
        filter "not HeaderOnly*"
            if options.mayLink then
                links( name )
            end
            
        filter { "*Debug", "platforms:x86" }
            defines "PREFIX=X86D_"
        
        filter { "*Debug", "platforms:x86_64" }
            defines "PREFIX=X86_64D_"
        
        filter { "*Release", "platforms:x86" }
            defines "PREFIX=X86R_"
        
        filter { "*Release", "platforms:x86_64" }
            defines "PREFIX=X86_64R_"
        
        filter { "*Coverage", "platforms:x86" }
            defines "PREFIX=X86C_"
        
        filter { "*Coverage", "platforms:x86_64" }
            defines "PREFIX=X86_64C_"

        filter { "not *Coverage", "not *Release", "not *Debug" }
            defines "PREFIX=X_"

        filter {}
			
	project( name )
		targetname( name )
        kind "StaticLib"     
                
		includedirs {
			name .. "/include/"
			}				
		     
        files { 
            name .. "/include/**.hpp",
            name .. "/include/**.h",
            name .. "/**.licenseheader"
            }
            
        filter "not HeaderOnly*"           
            files { 
			    name .. "/src/**.cpp"
                }

        filter {}


    if os.isdir( "bench" ) then

        if os.isfile( licenseheader ) then
            os.copyfile( licenseheader, path.join("bench", name .. ".licenseheader") )
        end
    
        project( name .. "-bench" )
                    
            kind "ConsoleApp"            
            location "bench"
            
            zpm.uses {
                "Zefiros-Software/GoogleBenchmark"
            }
            
            includedirs {			
                name .. "/include/",
                "bench/"
                }	
            
            files { 
                "bench/**.h",
                "bench/**.cpp",
                "bench/**.licenseheader"
                }

            excludes { 
                "bench/extern/**",
                "bench/assets/**"
            }
                        
            filter "not HeaderOnly*"
                if options.mayLink then
                    links( name )
                end
            
            filter {}
    end
    
    workspace()
end

function zefiros.setTestZPMDefaults( name, options )

    if options == nil then
        options = {}
    end

    configurations { "Test" }

    platforms { "x86" }

    startproject( name .. "-zpm-test" )
	location "zpm"
	objdir "bin/obj/"

    optimize "Speed"
	warnings "Extra"
    
    --filter "system:not macosx"
    --    linkgroups "On"

    filter "platforms:x86"
        targetdir "bin/x86/"
        debugdir "bin/x86/"
        architecture "x86"

    filter {}
			
	project( name .. "-zpm-test" )
				
		kind "ConsoleApp"
        
        zpm.uses "Zefiros-Software/GoogleTest"
		
		includedirs "./"
		
		files { 
			"**.h",
			"**.cpp"
			}

        excludes { 
            "extern/**",
            "assets/**"
         }
        
        defines "PREFIX=ZPM_"
    
    workspace()
end

zpm.newaction {
    trigger = "build-ci",
    description = "Build this library with a default structure",
    execute = function()

        if os.ishost("windows") then

            local vs = iif(os.getenv("TYPE") == "zpm", "vs2015", iif(os.getenv("VSTUD"), os.getenv("VSTUD"), "vs2015"))
    
            if os.getenv("TYPE") == "zpm" then

                local current = os.getcwd()
            
                os.chdir(path.join(_MAIN_SCRIPT_DIR, "test"))

                os.executef("zpmd %s --skip-lock --verbose", vs)   

                os.fexecutef("msbuild zpm/%s-ZPM.sln", _ARGS[1])

                os.chdir(current)
            else
                
                os.executef("zpmd %s --skip-lock --verbose", vs)   
                
                os.fexecutef("msbuild %s/%s.sln /property:Configuration=%s /property:Platform=%s", _ARGS[2], _ARGS[1], os.getenv("TYPE"), iif(os.getenv("PLAT"), os.getenv("PLAT"), "x64"))
            end
        else
            if os.getenv("TYPE") == "zpm" then

                local current = os.getcwd()
            
                os.chdir(path.join(_MAIN_SCRIPT_DIR, "test"))

                os.executef("zpm gmake --skip-lock")   
            
                os.chdir(path.join(_MAIN_SCRIPT_DIR, "test/zpm"))

                os.fexecutef("make")

                os.chdir(current)
            else
                

                os.executef("zpm gmake --skip-lock --verbose")   
                
                local current = os.getcwd()
                os.chdir(path.join(_MAIN_SCRIPT_DIR, _ARGS[2]))

                os.fexecutef("make config=%s_%s", os.getenv("TYPE"), os.getenv("ARCH"))

                os.chdir(current)
            end
        end
    end
}

zpm.newaction {
    trigger = "test-definition",
    description = "Test this definition with a default structure",
    execute = function()

        if os.ishost("windows") then
            
            os.executef("zpmd vs2015 --skip-lock --verbose")   

            os.fexecutef("msbuild %s.sln /property:Configuration=Test /property:Platform=Win32", _ARGS[1])
            os.fexecutef("bin\\Test\\%s.exe", _ARGS[1])
        else

            os.executef("zpm gmake --skip-lock --verbose")   

            os.fexecutef("make")
            os.fexecutef("./bin/Test/%s", _ARGS[1])
        end
    end
}

zpm.newaction {
    trigger = "build-ci-library",
    description = "Build this library with a default structure",
    execute = function()

        os.fexecutef("zpm run build-ci --verbose --skip-lock %s %s", _ARGS[1], _ARGS[2])
        os.fexecutef("zpm run test-ci --verbose %s %s", _ARGS[1], _ARGS[2])

    end
}

zpm.newaction {
    trigger = "build-ci-application",
    description = "Build this library with a default structure",
    execute = function()

        os.fexecutef("zpm run build-ci --verbose %s %s", _ARGS[1], _ARGS[2])
        os.fexecutef("zpm run test-ci --verbose %s %s", _ARGS[1], _ARGS[2])

    end
}

zpm.newaction {
    trigger = "test-ci",
    description = "Test this library with a default structure",
    execute = function()

        if os.ishost("windows") then       
            
            if os.getenv("TYPE") == "zpm" then
                os.fexecutef("test\\bin\\%s\\%s-zpm-test.exe", iif(os.getenv("ARCH"), os.getenv("ARCH"), "x86"), _ARGS[2])     
            else
                if os.getenv("TYPE") == "debug" then
                    os.fexecutef("bin\\%s\\%s-testd.exe", iif(os.getenv("ARCH"), os.getenv("ARCH"), "x86"), _ARGS[2])     
                else
                    os.fexecutef("bin\\%s\\%s-test.exe", iif(os.getenv("ARCH"), os.getenv("ARCH"), "x86"), _ARGS[2])     
                end
            end
        else
            
            if os.getenv("TYPE") == "zpm" then
                os.fexecutef("./test/bin/%s/%s-zpm-test", iif(os.getenv("ARCH"), os.getenv("ARCH"), "x86"), _ARGS[2])     
            else
                if os.getenv("TYPE") == "debug" then
                    os.fexecutef("./bin/%s/%s-testd", iif(os.getenv("ARCH"), os.getenv("ARCH"), "x86"), _ARGS[2])    
                elseif os.getenv("TYPE") == "coverage" then
                    os.fexecutef("./%s-testcd", _ARGS[2])     
                else
                    os.fexecutef("./bin/%s/%s-test", iif(os.getenv("ARCH"), os.getenv("ARCH"), "x86"), _ARGS[2])     
                end
            end
        end
    end
}

function zefiros.onLoad()

    if os.getenv("TRAVIS") then

        local gccVersion = os.getenv("GCC_VERSION")
        if not gccVersion then
            gccVersion = "6"
        end

        if os.ishost("linux") and not zpm.loader.config(('install.module.zefiros-software.miniconda.gcc-%s'):format(gccVersion)) then 
            zpm.loader.config:set(('install.module.zefiros-software.miniconda.gcc-%s'):format(gccVersion), "installed", true)
            os.execute("sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y")
            os.execute("sudo apt-get update -y")
        
            os.executef("sudo apt-get install gcc-%s g++-%s -y", gccVersion, gccVersion)
            os.executef("sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-%s 60", gccVersion)
            os.executef("sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-%s 60", gccVersion)
            os.executef("sudo update-alternatives --config gcc")
            os.executef("sudo update-alternatives --config g++")
            os.executef("sudo apt-get install gcc-%s-multilib g++-%s-multilib", gccVersion, gccVersion)
        
            -- for coverage
            os.execute("sudo pip install codecov")
        end
    end
end

return zefiros
