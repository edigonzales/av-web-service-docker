///usr/bin/env jbang "$0" "$@" ; exit $?
//JAVA 21+
//REPOS central
//REPOS guru=https://jars.interlis.guru/
//REPOS umleditor=https://jars.umleditor.org/
//REPOS interlis=https://jars.interlis.ch/
//DEPS ch.ehi.avwebservice:av-web-service:1.0.0-SNAPSHOT

import org.springframework.boot.SpringApplication;

public class avws {
    public static void main(String[] args) throws Exception {
        String mainClass = System.getProperty(
            "mainClass",
            "ch.ehi.av.webservice.Application"
        );

        SpringApplication.run(Class.forName(mainClass), args);
    }
}