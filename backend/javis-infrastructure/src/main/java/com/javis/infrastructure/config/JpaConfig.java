package com.javis.infrastructure.config;

import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@Configuration
@EntityScan(basePackages = "com.javis.domain")
@EnableJpaRepositories(basePackages = "com.javis.domain")
public class JpaConfig {}
