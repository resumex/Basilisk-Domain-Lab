@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'BasiliskLab.psm1'

    # Version number of this module.
    ModuleVersion = '1.0'

    # ID used to uniquely identify this module
    GUID = '7b50c9c1-bde1-4a98-b30f-8a4d27b439f5'

    # Author of this module
    Author = 'Adam Rice'

    # Copyright statement for this module
    Copyright = 'BSD 3-Clause unless explicitly noted otherwise'

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    ScriptsToProcess = @('Set-Domain.ps1', 'Set-RandomUsers.ps1')

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = '*'

    # Variables to export from this module
    VariablesToExport = '*'
}

