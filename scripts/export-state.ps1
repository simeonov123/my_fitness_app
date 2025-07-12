<#
  scripts\export-state.ps1
  Dumps MySQL data + exports Keycloak realm into /db.
  Run after `docker compose up -d` shows the stack "Up".
#>

$mysqlContainer    = "my_fitness_mysql"      # container_name in compose
$keycloakContainer = "my_fitness_keycloak"
$mysqlRootPass     = "rootpass"
$databases         = "keycloak myfitness"
$realm             = "myrealm"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item db -ItemType Directory -Force | Out-Null

# --- dump MySQL inside the container, then copy out ----------------------
$tmpSql = "/tmp/init-$stamp.sql"
& docker.exe exec $mysqlContainer sh -c `
  "mysqldump -uroot -p$mysqlRootPass --databases $databases > $tmpSql"

& docker.exe cp "${mysqlContainer}:${tmpSql}" "db\init-$stamp.sql"
& docker.exe exec $mysqlContainer rm -f $tmpSql
Write-Host "MySQL dump     → db\init-$stamp.sql"

# --- export Keycloak realm to /tmp, then copy out ------------------------
& docker.exe exec $keycloakContainer /opt/keycloak/bin/kc.sh export `
    --dir /tmp/export --realm $realm --users realm_file

& docker.exe cp "${keycloakContainer}:/tmp/export/${realm}-realm.json" `
               "db\$realm-realm-$stamp.json"
& docker.exe exec $keycloakContainer rm -rf /tmp/export
Write-Host "Realm export   → db\$realm-realm-$stamp.json"

Write-Host "`nExport completed successfully."
