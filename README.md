# Enterprise Spring Boot DevSecOps Platform

> **Note:** 🚧 This project is currently **under construction**. It was built primarily as a hands-on portfolio project to practice, integrate, and showcase proficiency with various enterprise-grade DevSecOps technologies, cloud-native deployments, and security practices.

## 📖 Project Overview

This project is a modern, cloud-native Enterprise Java application built with **Spring Boot 3**. It is designed to demonstrate a secure, robust back-end architecture paired with a complete **DevSecOps CI/CD pipeline**. The application acts as a secure RESTful API (Resource Server), authenticating users through an Identity and Access Management (IAM) provider, and fetching its runtime secrets dynamically from a centralized vault.

## 🛠️ Technologies & Tools Used

### **Application & Backend**
*   **Java 17**: Modern language features and LTS support.
*   **Spring Boot 3.2.0**: Core framework for building the REST API.
*   **Spring Data JPA / Hibernate**: Object-Relational Mapping for database interactions.
*   **PostgreSQL**: Relational database for persistent data storage.

### **Security & Secrets Management**
*   **Spring Security & OAuth2**: Acts as an OAuth2 Resource Server.
*   **Keycloak**: Open-source IAM provider for Identity Brokering and OAuth2/OpenID Connect (OIDC) JWT token generation.
*   **Spring Cloud Vault (HashiCorp Vault)**: Secure, centralized storage for dynamic secrets and application properties.

### **DevOps, CI/CD, & Containerization**
*   **Gradle**: Build automation tool.
*   **Docker**: Multi-stage builds using lightweight Alpine Linux images to package the application as an immutable artifact.
*   **Jenkins**: Automation server handling the declarative CI/CD pipeline (`Jenkinsfile`).
*   **Sonatype Nexus**: Private container registry used to securely store Docker images.
*   **Ansible**: Configuration management and continuous deployment (push-based deployment).
*   **Kubernetes / Red Hat OpenShift**: Container orchestration platform for the final deployment of the application and services.

---

## 🏗️ Architecture & Logic

### 1. Application Layer
The core of the system is a Spring Boot application. It exposes RESTful endpoints but requires a valid JSON Web Token (JWT) to access them. The token issuer is configured to be a Keycloak realm (`enterprise-realm`). Furthermore, instead of hardcoding database passwords or API keys, the application connects to HashiCorp Vault on startup (via Spring Cloud Vault) to securely fetch its sensitive environment variables.

### 2. The DevSecOps Pipeline
The automation logic is defined in a `Jenkinsfile` and consists of several stages:
1.  **Compile & Unit Test**: Jenkins pulls the code and uses the Gradle wrapper to compile the Java 17 source code and run unit tests.
2.  **Security Gate (IAM Validation)**: Before building the artifact, the pipeline explicitly tests the connection to Keycloak by requesting a client credentials grant token. If Keycloak fails to issue a token, the pipeline aborts.
3.  **Package Immutable Artifact**: Uses a multi-stage `Dockerfile`. It first compiles the `.jar` using an Eclipse Temurin JDK image, then copies only the compiled artifact into a lightweight JRE Alpine image to reduce the attack surface and image size.
4.  **Artifact Storage**: The newly minted Docker image is tagged with the Jenkins build number and pushed to a secure Sonatype Nexus repository.
5.  **Continuous Deployment (CD)**: Jenkins delegates the deployment process to **Ansible**. An Ansible playbook (`cd-deploy.yml`) uses the Kubernetes core module to push the `deployment.yaml` and `service.yaml` manifests directly to a Red Hat OpenShift cluster.

---

## 🚀 Getting Started

Since this is an enterprise-scale architecture, running it locally requires several infrastructure components.

1.  **Start Infrastructure Services**: You will need instances of PostgreSQL, Keycloak, and HashiCorp Vault running (typically via Docker Compose).
2.  **Configure Keycloak**: Set up a realm named `enterprise-realm` and a client named `spring-boot-api`.
3.  **Build the App**:
    ```bash
    ./gradlew clean build
    ```
4.  **Run Locally**:
    ```bash
    java -jar build/libs/enterprise-platform-0.0.1-SNAPSHOT.jar
    ```

*(More detailed setup instructions for the infrastructure components will be added as the project progresses).*
