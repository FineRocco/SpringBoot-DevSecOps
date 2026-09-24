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
*   **HashiCorp Vault**: Secure, centralized storage for dynamic secrets (database credentials) and application properties.

### **DevOps, CI/CD, & Infrastructure as Code (IaC)**
*   **Maven**: Build automation tool.
*   **Docker**: Multi-stage builds using lightweight Alpine Linux images to package the application as an immutable artifact.
*   **Jenkins**: Automation server handling the declarative CI/CD pipeline (`Jenkinsfile`).
*   **GitHub Webhooks & Ngrok**: Automated event-driven pipeline triggers.
*   **Sonatype Nexus 3**: Private container registry used to securely store Docker images.
*   **Ansible**: Infrastructure as Code (IaC) configuration management handling the push-based deployment.

---

## 🏗️ Architecture & Logic

### 1. Application Layer
The core of the system is a Spring Boot application exposing RESTful endpoints. The API is strictly secured and requires a valid JSON Web Token (JWT) to access them. The token issuer is configured to be a local Keycloak realm (`enterprise-realm`), and the cryptographic signature of the token is verified using Keycloak's JWKS endpoint.

Furthermore, instead of hardcoding database passwords or API keys in the source code (a major security risk), the application connects to **HashiCorp Vault** on startup to securely fetch its sensitive environment variables directly into memory.

### 2. The DevSecOps Pipeline
A deliberate architectural choice was made to use **Ansible** and **Local Docker** for deployments rather than a heavy orchestrator like Kubernetes/OpenShift. This demonstrates a lean, efficient Infrastructure as Code (IaC) approach. 

The automation logic is defined in a `Jenkinsfile` and consists of several stages:
1.  **Event Trigger**: A `git push` to GitHub triggers a webhook payload. An Ngrok secure tunnel forwards this payload into the local Jenkins server to automatically start the pipeline.
2.  **Compile & Unit Test**: Jenkins pulls the code and uses the Maven wrapper to compile the Java 17 source code and run unit tests.
3.  **Security Gate (IAM Validation)**: Before building the artifact, the pipeline explicitly tests the connection to Keycloak by requesting a client credentials grant token. If Keycloak fails to issue a token, the pipeline aborts.
4.  **Package Immutable Artifact**: Uses a multi-stage `Dockerfile` to compile the `.jar` and package it into a lightweight JRE Alpine image to reduce the attack surface.
5.  **Artifact Storage**: The newly minted Docker image is tagged with the Jenkins build number and pushed to a secure, private Sonatype Nexus Docker registry (port 8082).
6.  **Continuous Deployment (CD)**: Jenkins delegates the deployment process to **Ansible**. An Ansible playbook (`cd-deploy.yml`) acts as the deployment engineer: it stops the old container, pulls the fresh image from Nexus, and runs it natively on the local Docker engine while dynamically injecting the Vault routing environment variables.

---

## 🚀 Getting Started & Infrastructure Prerequisites

> **⚠️ Important:** This repository contains the application source code and the pipeline definition (`Jenkinsfile`). It **does not** automatically provision the underlying CI/CD infrastructure. To run this project locally, you must pre-configure the following services (e.g., via Docker Desktop):

### 1. Infrastructure Services Required
*   **PostgreSQL**: Running on port `5432` with a database named `userdb`.
*   **HashiCorp Vault**: Running in Dev Mode on port `8200`.
*   **Keycloak**: Running on port `9090`.
*   **Sonatype Nexus 3**: Running on port `8081`.
*   **Jenkins**: Running on port `8080` (Must have Docker Engine access and Ansible installed).

### 2. Manual Configurations Required
**Keycloak**:
*   Create a realm named `enterprise-realm`.
*   Create a client named `spring-boot-api` with **Service Accounts Enabled** (Client Credentials grant).

**Sonatype Nexus**:
*   Create a **docker (hosted)** repository on HTTP port `8082`.
*   Activate the **Docker Bearer Token Realm** in the Security settings.

**Jenkins**:
*   Install the Docker Pipeline plugin.
*   Add Global Credentials:
    *   `keycloak-secret` (Secret Text): The client secret from Keycloak.
    *   `nexus-credentials` (Username/Password): Your Nexus admin login.
*   Create a new Pipeline job and point it to this Git repository.

### 3. Running the Project
1.  **Initialize Vault**: Because Dev Mode Vault containers wipe their memory on restart, manually inject the database secrets into Vault before running the application:
    ```bash
    curl -X POST http://localhost:8200/v1/secret/data/enterprise-app \
      -H "X-Vault-Token: root" \
      -H "Content-Type: application/json" \
      -d "{\"data\":{\"spring.datasource.username\":\"admin\",\"spring.datasource.password\":\"password\"}}"
    ```
2.  **Trigger the Pipeline**: Push code to GitHub to trigger the Jenkins pipeline (via Ngrok Webhook), which will compile the code, pass the security gate, push the image to Nexus, and use Ansible to deploy the `local-enterprise-app` container onto port `8088`.
3.  **Test the API**: Use Postman to fetch an OAuth 2.0 token from Keycloak and make a `POST` request to `http://localhost:8088/api/users`.
## 📚 API Reference

Below is the complete list of REST API endpoints exposed by the application, including the Identity Provider (Keycloak) token endpoint. 

> **Authentication Required:** All `/api/users` endpoints require a valid OAuth 2.0 `Bearer Token` passed in the `Authorization` header.

### 1. Get Keycloak Token
Fetches an access token from the Identity Provider.
*   **Method**: `POST`
*   **URL**: `http://localhost:9090/realms/enterprise-realm/protocol/openid-connect/token`
*   **Body (x-www-form-urlencoded)**:
    *   `grant_type`: `client_credentials`
    *   `client_id`: `spring-boot-api`
    *   `client_secret`: *(your-client-secret)*

### 2. Create User
Creates a new user in the PostgreSQL database.
*   **Method**: `POST`
*   **URL**: `http://localhost:8088/api/users`
*   **Body (JSON)**:
    ```json
    {
      "name": "Jane Doe",
      "email": "jane@example.com"
    }
    ```

### 3. Get All Users
Retrieves a JSON array of all registered users.
*   **Method**: `GET`
*   **URL**: `http://localhost:8088/api/users`

### 4. Get User by ID
Retrieves a specific user by their database ID.
*   **Method**: `GET`
*   **URL**: `http://localhost:8088/api/users/{id}` (e.g., `/api/users/1`)

### 5. Modify User
Updates the information for an existing user.
*   **Method**: `PUT`
*   **URL**: `http://localhost:8088/api/users/{id}`
*   **Body (JSON)**:
    ```json
    {
      "name": "Jane Smith",
      "email": "janesmith@example.com"
    }
    ```

### 6. Delete User
Removes a user from the database.
*   **Method**: `DELETE`
*   **URL**: `http://localhost:8088/api/users/{id}`
