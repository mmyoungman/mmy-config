cmd -new_console:t:"database":d:C:\Users\mark\projects\explore-education-statistics\src /k "cd C:\Users\mark\projects\explore-education-statistics\src & docker-compose up db"

cmd -new_console:t:"admin":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Admin /k "sleep 5 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Admin & dotnet build & dotnet run"

cmd -new_console:t:"data":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Data.Api /k "sleep 5 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Data.Api & dotnet build & dotnet run"

cmd -new_console:t:"content":d:C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Content.Api /k "sleep 5 & cd C:\Users\mark\projects\explore-education-statistics\src\GovUk.Education.ExploreEducationStatistics.Content.Api & dotnet build & dotnet run"

cmd -new_console:t:"bash":d:C:\Users\mark\projects\explore-education-statistics /c ""%ConEmuDir%\..\git-for-windows\bin\bash" --login -i" 