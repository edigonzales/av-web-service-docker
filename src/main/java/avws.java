///usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 21
//REPOS central
//REPOS guru=https://jars.interlis.guru/
//REPOS umleditor=https://jars.umleditor.org/
//REPOS interlis=https://jars.interlis.ch/
//DEPS ch.ehi.avwebservice:av-web-service:1.0.0-SNAPSHOT

import org.springframework.boot.SpringApplication;
import org.springframework.context.annotation.Configuration;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

public class avws {
    public static void main(String[] args) throws Exception {
        String mainClass = System.getProperty(
                "mainClass",
                "ch.ehi.av.webservice.Application"
        );

        SpringApplication.run(
                new Class<?>[] {
                        Class.forName(mainClass),
                        SpaConfig.class
                },
                args
        );
    }

    @Configuration
    static class SpaConfig {

        @Controller
        static class SpaForwardController {

            @GetMapping({
                    "/app",
                    "/app/"
            })
            public String appRoot() {
                return "forward:/app/index.html";
            }

            @GetMapping({
                    "/app/{path:^(?!assets$)[^\\.]*$}",
                    "/app/{path:^(?!assets$)[^\\.]*$}/**"
            })
            public String appRoute() {
                return "forward:/app/index.html";
            }
        }
    }
}