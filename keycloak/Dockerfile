# keycloak/Dockerfile
FROM quay.io/keycloak/keycloak:latest

# Copy your custom EventListener / SPI JAR into the providers folder
COPY keycloak-trainer-provisioning-spi-1.0.0.jar /opt/keycloak/providers/

# No ENTRYPOINT override – we still use Keycloak’s default kc.sh
