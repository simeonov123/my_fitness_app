package com.mvfitness.mytrainer2.security;

import org.springframework.context.annotation.Configuration;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority; // <-- ADD THIS
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.stream.Collectors;

@Configuration
public class JwtRoleConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    @Override
    public Collection<GrantedAuthority> convert(Jwt jwt) {
        // 1) get realm roles
        Map<String, Object> realmAccess = jwt.getClaim("realm_access");
        if (realmAccess == null || realmAccess.get("roles") == null) {
            return Collections.emptyList();
        }

        Collection<String> roles = (Collection<String>) realmAccess.get("roles");

        // 2) Map "TRAINER" => "ROLE_TRAINER"
        return roles.stream()
                .map(roleName -> "ROLE_" + roleName.toUpperCase())  // e.g. ROLE_TRAINER
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toSet());
    }
}
