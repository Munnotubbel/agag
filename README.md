# Ententeich Microservices Projekt

## 1. Infrastruktur

### 1.1 Kind Kubernetes Cluster
- **Beschreibung**: Lokaler Kubernetes-Cluster für Entwicklungszwecke.
- **Version**: Nicht spezifiziert, empfohlen wird die neueste stabile Version.
- **Konfiguration**: 
  - Single-Node-Cluster (Control-Plane fungiert auch als Worker)
  - Portmappings:
    - 80:30644 (HTTP)
    - 443:31539 (HTTPS)
    - 22:30413 (SSH)
  - Ingress-Controller: NGINX (vorinstalliert)
- **Besonderheiten**: 
  - Unterstützt LoadBalancer-Services durch MetalLB
  - Integrierte lokale Registry

### 1.2 Docker Registry
- **Typ**: Lokale Registry in Docker-Container
- **Adresse**: localhost:5000
- **Zweck**: Speicherung und Verwaltung von Docker-Images für Microservices
- **Konfiguration**: Muss als insecure-registry in Docker-Daemon konfiguriert sein

### 1.3 GitLab
- **Deployment**: Über Helm Chart im Kind-Cluster
- **Version**: 17.4.2 (basierend auf der Helm-Chart-Konfiguration)
- **Komponenten**:
  - GitLab Core (Webservice, Sidekiq)
  - GitLab Shell
  - Gitaly
  - Registry
  - NGINX Ingress Controller
  - Redis
  - PostgreSQL
- **URL**: https://gitlab.tubbel-top (intern erreichbar)
- **Besonderheiten**: 
  - Verwendet selbstsigniertes TLS-Zertifikat
  - Runner für CI/CD integriert

## 2. Microservices

### 2.1 Backente
- **Beschreibung**: Backend-Service
- **Technologie**: Rust (basierend auf Cargo.toml)
- **Repository**: GitLab-Projekt unter der Gruppe "Ententeich"
- **Containerisierung**: Dockerfile vorhanden
- **Deployment**: Kubernetes-Manifeste in k8s/ Verzeichnis

### 2.2 Frontente
- **Beschreibung**: Frontend-Service
- **Technologie**: Vermutlich JavaScript/Node.js (basierend auf package.json)
- **Repository**: GitLab-Projekt unter der Gruppe "Ententeich"
- **Containerisierung**: Dockerfile vorhanden
- **Deployment**: Kubernetes-Manifeste in k8s/ Verzeichnis
- **Webserver**: NGINX-Konfiguration vorhanden

### 2.3 CI/CD
- **Beschreibung**: Separates Projekt für CI/CD-Konfigurationen
- **Repository**: GitLab-Projekt unter der Gruppe "Ententeich"
- **Inhalt**: 
  - main-config.yml: Hauptkonfigurationsdatei
  - variables.yml: Definierte Variablen für CI/CD
  - templates/: Wiederverwendbare Job-Templates

## 3. Infrastruktur als Code

### 3.1 OpenTofu (Terraform-kompatibel)
- **Zweck**: Automatisierte Infrastruktur- und Ressourcenverwaltung
- **Hauptmodule**:
  - GitLab-Setup: Konfiguration der GitLab-Instanz
  - Kubernetes-Ressourcen: Deployment von Kubernetes-Objekten
  - GitLab-Runner: Konfiguration und Deployment des GitLab-Runners
- **Besonderheiten**:
  - Verwendet OpenTofu statt Terraform
  - Integriert mit GitLab für Zustandsverwaltung

### 3.2 Ansible
- **Zweck**: Konfigurationsmanagement und Anwendungsdeployment
- **Hauptplaybooks**:
  - site.yml: Hauptplaybook für gesamtes Setup
  - Rollen für verschiedene Komponenten (Docker, GitLab, etc.)

## 4. Continuous Integration / Continuous Deployment (CI/CD)

### 4.1 GitLab CI/CD
- **Runner**: Kubernetes-basierter Runner im Cluster
- **Konfiguration**: .gitlab-ci.yml in jedem Projekt
- **Stages**: Vermutlich Build, Test, Deploy (basierend auf typischen Setups)
- **Artefakte**: Docker-Images werden in die lokale Registry gepusht

### 4.2 Kubernetes Integration
- **GitLab Kubernetes Agent**: Ermöglicht direkte Interaktion zwischen GitLab und Kubernetes
- **Deployment**: Automatisiertes Deployment in den Kind-Cluster

## 5. Monitoring und Logging

### 5.1 Uptime Kuma
- **Zweck**: Überwachung der Verfügbarkeit von Services
- **Deployment**: Als Kubernetes Deployment im Monitoring-Namespace
- **Zugriff**: Vermutlich über Ingress oder NodePort

### 5.2 Prometheus (optional, basierend auf typischen Setups)
- **Zweck**: Metriken-Sammlung und Monitoring
- **Deployment**: Möglicherweise als Teil des GitLab-Helm-Charts

## 6. Netzwerk und Sicherheit

### 6.1 Ingress
- **Controller**: NGINX Ingress Controller
- **TLS**: Selbstsignierte Zertifikate, verwaltet durch cert-manager
- **Routing**: HTTP/HTTPS-Verkehr zu verschiedenen Services

### 6.2 Sicherheit
- **GitLab**: Integrierte Authentifizierung und Autorisierung
- **Kubernetes**: RBAC für Zugriffssteuerung
- **Netzwerkpolicies**: Nicht explizit erwähnt, aber empfohlen für Produktionsumgebungen

## 7. Entwicklungsprozess

### 7.1 Lokale Entwicklung
- Kind-Cluster ermöglicht lokales Testen der gesamten Infrastruktur
- Direkte Interaktion mit lokaler GitLab-Instanz

### 7.2 Code-Verwaltung
- GitLab für Versionskontrolle und Kollaboration
- Branching-Strategie: Nicht spezifiziert, empfohlen GitFlow oder Trunk-Based Development

### 7.3 Deployment-Workflow
1. Code-Push zu GitLab
2. CI/CD-Pipeline wird ausgelöst
3. Build und Test der Anwendung
4. Erstellung und Push von Docker-Images zur lokalen Registry
5. Deployment in Kubernetes-Cluster über GitLab Kubernetes Agent

## 8. Erweiterbarkeit und Skalierung

- Modularer Aufbau ermöglicht einfaches Hinzufügen neuer Microservices
- Kind-Cluster kann für größere Setups durch vollwertige Kubernetes-Cluster ersetzt werden
- GitLab kann bei Bedarf auf externe Instanz migriert werden
