-- iOS / iOS Simulator
local metadata =
{
    plugin =
    {
        format = "staticLibrary",
 
        -- This is the name without the "lib" prefix
        staticLibs = { "MOLPay", },
 
        frameworks = {},
        frameworksOptional = {},
    },
    coronaManifest = {
        dependencies = {
        },
    },
}
 
return metadata