## Salesforce Spring Boot Rule for Bazel

This folder contains the Salesforce [Spring Boot](https://spring.io/guides/gs/spring-boot/) rule for the [Bazel](https://bazel.build/) build system.
It enables Bazel to build Spring Boot applications and package them as an executable jar file.
The executable jar is the best way to deploy your Spring Boot application in production environments.

This Bazel rules are based on Salesforce's *bazel-springboot-rule* [GitHub repository](https://github.com/salesforce/bazel-springboot-rule) and the [bazel-springboot-rule](https://github.com/salesforce/bazel-springboot-rule/tree/master/tools/springboot) was copied into this folder for the shared Bazel rules.
