package com.javis.infrastructure.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@Configuration
@EnableJpaRepositories(
        basePackages = {"com.javis"},
        repositoryImplementationPostfix = "Impl")
public class JpaConfig {}
