package com.javis.application;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication(scanBasePackages = "com.javis")
@EnableJpaAuditing
public class JavisApplication {

    public static void main(String[] args) {
        SpringApplication.run(JavisApplication.class, args);
    }
}
