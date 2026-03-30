-- db/init-keycloak.sql

CREATE DATABASE IF NOT EXISTS keycloak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'keycloak_user'@'%' IDENTIFIED BY 'mvf-kc-db-H7y2L6cM4s';
GRANT ALL PRIVILEGES ON keycloak.* TO 'keycloak_user'@'%';
FLUSH PRIVILEGES;
