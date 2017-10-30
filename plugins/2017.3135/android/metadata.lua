-- Android
local metadata =
{
    plugin =
    {
        format = "jar",
        manifest = 
        {
            permissions = {},
            usesPermissions =
            {
                "android.permission.INTERNET",
                "android.permission.WRITE_EXTERNAL_STORAGE",
            },
            usesFeatures = {},
            applicationChildElements ={},
        }
    }
}
 
return metadata