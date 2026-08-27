# Projeto DevSecOps AWS: Pipeline de IaC Segura

![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GITHUB_ACTIONS-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Checkov](https://img.shields.io/badge/CHECKOV-000000?style=for-the-badge&logo=security&logoColor=white)

> **O Desafio:** Subir uma infraestrutura AWS altamente disponível e 100% automatizada no Free Tier. O foco central é segurança estrutural (Shift-Left): zero uso de credenciais estáticas e bloqueio automático de vulnerabilidades antes que o código chegue na AWS.

---

## Arquitetura da Solução

A esteira de CI/CD é baseada no GitHub Actions e integrada nativamente com a AWS:

*   **No Pull Request:** O GitHub Actions autentica temporariamente, gera o plano do Terraform e roda o Checkov. Qualquer falha de segurança bloqueia o merge automaticamente.
*   **Na branch Main (Produção):** Após a validação, a pipeline aplica a infraestrutura definitiva na AWS (VPC, Security Groups e Auto Scaling Group).

<p align="center">
  <img src="./docs/arquitetura.png" alt="Arquitetura da Solução" width="800">
</p>

---

## Evidências de Execução

Como a automação, a validação de segurança e o deploy se comportam na prática:

### 1. Shift-Left Security (Bloqueio Preventivo)
> O Checkov trava o PR ao identificar falhas de segurança — neste caso, um Security Group configurado intencionalmente com a porta aberta para o mundo (0.0.0.0/0) —, impedindo o avanço de código vulnerável.

<p align="center">
  <img src="./docs/checkov-block.png" alt="Bloqueio Preventivo - Checkov" width="900">
</p>

### 2. Pipeline de Deploy (GitHub Actions)
> Deploy limpo na branch principal. Os logs mostram a autenticação *passwordless* via OIDC fechando com sucesso e as etapas do Terraform (`fmt`, `plan`, `apply`) rodando sem intervenção manual.

<p align="center">
  <img src="./docs/pipeline-success.png" alt="Execução do Pipeline" width="800">
</p>

### 3. Estado Final (Infraestrutura Provisionada)
> Recursos provisionados na AWS: VPC estruturada, Auto Scaling Group (ASG) com as instâncias ativas e tags aplicadas corretamente via IaC.

<p align="center">
  <img src="./docs/aws-console.png" alt="Console AWS - Instâncias e VPC" width="800">
</p>

### 4. Validação Funcional (Acesso Externo)
> A aplicação responde ao acesso externo. O script de *User Data* rodou no boot da instância dentro do ASG, inicializando o web server na porta 80.

<p align="center">
  <img src="./docs/app-running.png" alt="Servidor Web Ativo" width="800">
</p>

### Nota Arquitetural: Trade-off entre TLS (HTTPS) e FinOps
> Por que a aplicação responde em HTTP em vez de HTTPS? Essa foi uma decisão deliberada de engenharia para manter o laboratório 100% dentro do AWS Free Tier. Habilitar criptografia em trânsito exigiria um domínio registrado e um Application Load Balancer (ALB) para terminação SSL, gerando custos contínuos. Como o foco deste projeto é DevSecOps na esteira de CI/CD (OIDC, Least Privilege e automação de IaC), abri mão do tráfego web criptografado na ponta para priorizar a otimização de custos.

---

## Destaques Técnicos

Principais ferramentas e decisões de engenharia aplicadas no projeto:

*   **Infraestrutura como Código (IaC):** Terraform 1.10+ organizando VPC, Subnets e ASG em módulos, facilitando a reutilização e escalabilidade do código.
*   **Gestão de Estado Otimizada:** Uso do *Native State Locking* do Terraform direto no S3, cortando a necessidade (e a complexidade) de manter uma tabela no DynamoDB só para controle de estado.
*   **Segurança (Least Privilege):** A IAM *Role* assumida pelo GitHub Actions tem escopo restrito. Nada de `AdministratorAccess`; as políticas liberam apenas o gerenciamento dos serviços específicos de rede e EC2.
*   **Autenticação via OIDC:** Integração entre AWS e GitHub usando OpenID Connect. Sem *Access/Secret Keys* fixas e expostas, o risco de vazamento de credenciais cai drasticamente.
*   **Resiliência (Auto Scaling):** Em vez de instâncias EC2 soltas, a infraestrutura roda dentro de um Auto Scaling Group (ASG), garantindo que a aplicação se recupere sozinha em caso de falhas.

---

## Instruções de Reprodução

Para reproduzir este ambiente na sua conta, siga os passos:

1. **Configuração OIDC (AWS):** Crie um *Identity Provider* no Console do IAM apontando para `token.actions.githubusercontent.com`.
2. **IAM Role (AWS):** Crie uma *Role* com uma *Trust Policy* amarrada ao seu repositório do GitHub e anexe a política com as permissões de *Least Privilege*.
3. **Backend S3 (AWS):** Crie manualmente um bucket S3 privado com versionamento ativo. Atualize o arquivo `environments/dev/providers.tf` com o nome desse bucket.
4. **Secrets (GitHub):** No repositório, crie a *Secret* `AWS_ROLE_ARN` com o ARN da Role criada no Passo 2.
5. **Deploy:** Faça um push para a branch `main` ou abra um *Pull Request* para disparar a automação.

## Descomissionamento

Para evitar surpresas no cartão de crédito, destrua os recursos rodando os comandos abaixo localmente (é necessário ter as credenciais da AWS configuradas na sua máquina):

```bash
cd environments/dev
terraform init
terraform destroy -auto-approve
