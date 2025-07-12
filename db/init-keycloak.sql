-- db/init-keycloak.sql

CREATE DATABASE IF NOT EXISTS keycloak;
CREATE USER IF NOT EXISTS 'keycloak_user'@'%' IDENTIFIED BY 'keycloakpass';
GRANT ALL ON keycloak.* TO 'keycloak_user'@'%';
FLUSH PRIVILEGES;
