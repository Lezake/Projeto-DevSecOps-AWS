# Projeto DevSecOps AWS: Pipeline de IaC Segura

![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/TERRAFORM-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GITHUB_ACTIONS-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Checkov](https://img.shields.io/badge/CHECKOV-000000?style=for-the-badge&logo=security&logoColor=white)

> **Desafio de Negócio:** Provisionar infraestrutura de alta disponibilidade na nuvem de forma 100% automatizada, eliminando o risco de vazamento de credenciais estáticas e garantindo que vulnerabilidades de segurança sejam bloqueadas antes da aplicação na AWS (*Shift-Left Security*). Tudo operando dentro do limite gratuito (Free Tier).

---

## Arquitetura da Solução

O fluxo de automação é orientado a eventos no repositório e integrado nativamente aos serviços da AWS:

*   **Em ambiente de Pull Request:** O GitHub Actions solicita credenciais temporárias, gera o plano do Terraform e executa o Checkov. Falhas de segurança bloqueiam a aprovação do código.
*   **Em ambiente de Produção (Main):** Após validação e *merge*, o pipeline aplica a infraestrutura definitiva na AWS (VPC, Security Groups e Auto Scaling Group).

<div align="center">

![Arquitetura da Solução](./docs/arquitetura.png)

</div>

---

## Evidências de Execução

Demonstração do ciclo completo da automação de integração contínua, validação de segurança e provisionamento na nuvem:

### 1. Shift-Left Security (Bloqueio Preventivo)
> Atuação do Checkov interrompendo o pipeline de *Pull Request* após identificar uma falha de segurança injetada intencionalmente (Security Group expondo porta globalmente), garantindo que código inseguro não avance.

<div align="center">

![Bloqueio Preventivo - Checkov](./docs/checkov-block.png)

</div>

### 2. Pipeline de Deploy (GitHub Actions)
> Registros de execução com sucesso na branch principal. O log evidencia a autenticação via OIDC e a aplicação correta dos passos de inicialização, formatação, planejamento e deploy (`terraform apply`).

<div align="center">

![Execução do Pipeline](./docs/pipeline-success.png)

</div>

### 3. Estado Final (Infraestrutura Provisionada)
> Comprovação da infraestrutura alocada na AWS. Auto Scaling Group operando com instâncias ativas e a VPC devidamente configurada, isolados sob as *tags* definidas no provisionamento via IaC.

<div align="center">

![Console AWS - Instâncias e VPC](./docs/aws-console.png)

</div>

### 4. Validação Funcional (Acesso Externo)
> Confirmação da integridade da aplicação web. O script de *User Data* foi executado com sucesso durante o *boot* da instância no ASG, respondendo requisições HTTP na porta autorizada.

<div align="center">

![Servidor Web Ativo](./docs/app-running.png)

</div>

### Nota Arquitetural: Trade-off entre TLS/SSL e FinOps (Free Tier)
> Embora o núcleo deste projeto seja DevSecOps, o artefato final (a aplicação web) é exposto via HTTP (porta 80) em vez de HTTPS (porta 443). Essa é uma decisão de engenharia deliberada (*Trade-off*) para manter a arquitetura estritamente dentro do AWS Free Tier. A implementação de criptografia em trânsito (HTTPS) exigiria um domínio FQDN registrado e o provisionamento de um Application Load Balancer (ALB) para realizar a terminação SSL, o que gera custos contínuos não cobertos integralmente pela camada gratuita. Portanto, o escopo de segurança deste laboratório está intencionalmente focado na proteção da esteira de CI/CD, gestão de identidade sem senhas e políticas de acesso restritas, priorizando a otimização de custos.

---

## Destaques Técnicos

A solução foi desenvolvida com foco em automação moderna e governança de nuvem:

*   **Infraestrutura como Código (IaC):** O provisionamento do ambiente (VPC, Subnets, Launch Templates e ASG) foi construído utilizando Terraform 1.10+, adotando a estrutura modular para escalabilidade de código.
*   **Gestão de Estado Otimizada:** Utilização do recurso de *Native State Locking* do Terraform suportado diretamente pelo Amazon S3, eliminando o custo e a complexidade arquitetural de manter tabelas no DynamoDB.
*   **Segurança (Least Privilege):** A IAM Role assumida pelo GitHub Actions foi configurada com políticas estritas, concedendo apenas as permissões necessárias para gerenciar serviços específicos de rede e computação, rejeitando o uso de `AdministratorAccess`.
*   **Autenticação OIDC (OpenID Connect):** Estabelecimento de relação de confiança direta entre a AWS e o GitHub. A eliminação do uso de *Access Keys* e *Secret Keys* fixas mitiga drasticamente a superfície de ataques por vazamento de credenciais.
*   **Resiliência (Auto Scaling):** Substituição da implantação de instâncias EC2 autônomas por um Auto Scaling Group, assegurando alta disponibilidade e capacidade de autorrecuperação da aplicação sem intervenção manual.

---

## Instruções de Reprodução

Para auditar ou reproduzir este ambiente de infraestrutura, siga os passos abaixo:

1. **Configuração OIDC (AWS):** Crie um *Identity Provider* no Console IAM apontando para `token.actions.githubusercontent.com`.
2. **IAM Role (AWS):** Crie uma *Role* com uma *Trust Policy* restrita ao seu repositório GitHub e anexe a política de permissões de *Least Privilege* necessária para os serviços.
3. **Backend S3 (AWS):** Provisione manualmente (via Console da AWS) um bucket Amazon S3 privado e com versionamento ativado. Atualize o arquivo `environments/dev/providers.tf` com o nome do seu bucket.
4. **Secrets (GitHub):** Configure a *Secret* de repositório `AWS_ROLE_ARN` contendo o ARN da Role criada no Passo 2.
5. **Deploy:** Execute o push para a branch `main` ou abra um *Pull Request* para acionar a esteira.

## Descomissionamento

Para evitar custos residuais na conta AWS, proceda com a destruição dos recursos executando a rotina abaixo na máquina local (requer credenciais da AWS configuradas no seu ambiente):

```bash
cd environments/dev
terraform init
terraform destroy -auto-approve
