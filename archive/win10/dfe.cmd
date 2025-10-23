cmd -new_console:t:"database":d:C:\Users\mark\projects\explore-education-statistics\src /k "cd C:\Users\mark\projects\explore-education-statistics\src & docker-compose up db"

cmd -new_console:t:"azure-emu":d:"C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator" /k "sleep 5 & AzureStorageEmulator.exe start"

cmd -new_console:t:"data":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Data.Api /k "sleep 10 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Data.Api & dotnet clean & dotnet build & dotnet run"

cmd -new_console:t:"content":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Content.Api /k "sleep 10 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Content.Api & dotnet clean & dotnet build & dotnet run"

cmd -new_console:t:"admin":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Admin /k "sleep 15 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Admin & dotnet clean & dotnet build & dotnet run"

cmd -new_console:t:"frontend":d:C:\Users\mark\projects\explore-education-statistics\src\explore-education-statistics-frontend /k "sleep 15 & cd C:\Users\mark\projects\explore-education-statistics\src\explore-education-statistics-frontend & npm run start:local"

cmd -new_console:t:"data-processor":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Data.Processor /k "sleep 20 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Data.Processor & C:\Users\mark\.Rider2019.2\config\azure-functions-coretools\3.0.2009\func.exe host start --port 7071 --pause-on-error"

cmd -new_console:t:"publisher":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Publisher /k "sleep 20 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Publisher & C:\Users\mark\.Rider2019.2\config\azure-functions-coretools\3.0.2009\func.exe host start --port 7072 --pause-on-error"

cmd -new_console:t:"notifier":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Notifier /k "sleep 20 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Notifier & C:\Users\mark\.Rider2019.2\config\azure-functions-coretools\3.0.2009\func.exe host start --port 7073 --pause-on-error"

cmd -new_console:t:"bash":d:C:\Users\mark\projects\explore-education-statistics /c ""%ConEmuDir%\..\git-for-windows\bin\bash" --login -i" 
