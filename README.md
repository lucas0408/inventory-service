# Microserviço de Produtos para E-commerce

[![Elixir](https://img.shields.io/badge/Elixir-4B275F?style=for-the-badge&logo=elixir&logoColor=white)](https://elixir-lang.org/)
[![Ecto](https://img.shields.io/badge/Ecto-45803D?style=for-the-badge&logo=elixir&logoColor=white)](https://hexdocs.pm/ecto/Ecto.html)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-FF6600?style=for-the-badge&logo=rabbitmq&logoColor=white)](https://www.rabbitmq.com/)
[![Poolboy](https://img.shields.io/badge/Poolboy-1B1F23?style=for-the-badge&logoColor=white)](https://elixirschool.com/pt/lessons/misc/poolboy)

## 📋 Visão Geral

Este repositório contém o microserviço de gerenciamento de produtos para uma plataforma de e-commerce, desenvolvido em Elixir. O serviço resolve o desafio crítico de performance e disponibilidade em catálogos de produtos, onde altos volumes de consultas e picos de acesso frequentemente degradam a experiência do usuário e impactam vendas.

Nossa solução aproveita o modelo de concorrência do Elixir/OTP e utiliza Poolboy para gerenciamento dinâmico de workers, oferecendo tempos de resposta consistentes mesmo sob carga extrema, garantindo que o catálogo permaneça responsivo em todos os cenários de tráfego.

### 🚀 Características Principais

- **Pool dinâmico de workers** com Poolboy para gerenciamento eficiente de conexões de clientes
- **Arquitetura baseada em processos concorrentes** com GenServer para máxima performance
- **Escalabilidade automática** para lidar com picos de tráfego sem intervenção manual
- **Comunicação assíncrona** com outros microserviços via RabbitMQ através de uma única fila CRUD
- **Persistência de dados** otimizada com Ecto
- **Resiliência** através de estratégias de supervisão avançadas

## 🏗️ Arquitetura

O microserviço de produtos é estruturado seguindo os princípios de design OTP (Open Telecom Platform) do Elixir/Erlang, maximizando a tolerância a falhas, escalabilidade e desempenho através de uma arquitetura baseada em processos supervisionados.

![Árvore de Processos](https://github.com/user-attachments/assets/b07e6a77-dc5c-4b34-afa6-62330f66224c)

### Componentes Principais:

Os componentes são organizados em uma hierarquia de supervisão que garante resiliência e escalabilidade:

1 **`InventoryService.Application`**: Ponto de entrada que orquestra o ciclo de vida de todos os processos usando estratégia `rest_for_one`.

2 **`InventoryService.RabbitSupervisor`**: Gerencia os componentes de comunicação assíncrona via RabbitMQ.
  - **`RabbitMQProducer`**: Publica mensagens e eventos para outros microsserviços.
  - **`RabbitMQConsumer`**: Processa mensagens da fila CRUD única `product.operations`.

3 **`InventoryService.ProcessRegistry`**: Implementa um registro global de processos para localização por nome em ambientes distribuídos.

4 **`InventoryService.Repo`**: Gerencia conexões otimizadas com o banco de dados através do Ecto.

5 **`InventoryService.InitSupervisor`**: Inicializa e gerencia pools dinâmicos de workers para processamento concorrente.
  - **`:poolboy`**: Escalona dinamicamente instâncias de `InventoryService.Stock` sob estratégia `one_for_one`.
  - **`PoolSupervisor`**: Administra workers de banco de dados para consultas concorrentes.

6 **`InventoryService.Stock`**: Implementa a lógica de negócios do inventário em múltiplas instâncias gerenciadas pelo poolboy.

7 **`InventoryService.DatabaseWorker`**: Executa operações otimizadas de banco de dados com alta concorrência.

## 🛠️ Tecnologias Utilizadas

- **Elixir**: Linguagem funcional otimizada para sistemas concorrentes e distribuídos
- **GenServer**: Framework para implementação de serviços com estado em Elixir
- **Supervisor**: Gerenciamento de processos com estratégias de reinício
- **Poolboy**: Sistema de pooling dinâmico para gerenciamento eficiente de workers
- **Ecto**: Framework ORM para persistência de dados
- **RabbitMQ**: Sistema de mensageria para comunicação entre microserviços

## 📦 Instalação

### Pré-requisitos

- Elixir 1.14+
- Erlang OTP 25+
- PostgreSQL 14+
- RabbitMQ 3.10+

### Configuração

_Detalhes de configuração serão adicionados futuramente._

## 🚦 Exemplo de Uso

### Comunicação via RabbitMQ

O serviço utiliza uma única fila CRUD com discriminador por tipo de operação, otimizando a arquitetura de mensageria:

- `product.operations` - Fila única para todas as operações CRUD, com roteamento interno baseado no campo `process`
- `inventory.sync` - Para sincronização com o serviço de inventário

Exemplo de mensagem para a fila de produtos:

```json
{
  "process": "add",
  "product": {
    "product_name": "arroz",
    "quantity": 150,
    "purchase_price": 5.75,
    "sale_price": 7.99,
    "expiration_date": "2025-12-31"
  }
}
```

> **Justificativa para Fila Única**: Escolhemos uma fila única CRUD para simplificar a topologia do sistema e o gerenciamento de consumidores. Esta arquitetura tem mostrado excelente performance em nossos testes sob carga, onde o Poolboy gerencia dinamicamente os workers que consomem desta fila.

## 📜 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE.md](LICENSE.md) para mais detalhes.

## 🔗 Links Úteis

- [Documentação do Elixir](https://elixir-lang.org/docs.html)
- [Documentação do GenServer](https://hexdocs.pm/elixir/GenServer.html)
- [Documentação do Ecto](https://hexdocs.pm/ecto/Ecto.html)
- [Documentação do RabbitMQ](https://www.rabbitmq.com/documentation.html)
