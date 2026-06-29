# 🏨 Dormez Hotel - App Mobile

Aplicativo móvel para gerenciamento de hotéis, desenvolvido em **Flutter** para a disciplina de Programação Para Dispositivos Móveis. O app consome uma API Spring Boot segura com autenticação via Token JWT.

## 🔑 Credenciais para Teste 
Para acessar o sistema com privilégios de Administrador, utilize os dados abaixo na tela de login:

* **E-mail:** `admin@hotel.com`
* **Senha:** `123`

> ⚠️ **Nota sobre a inicialização:** Como a API está hospedada no plano gratuito do Render (render.com), o servidor entra em modo de espera após alguns minutos de inatividade. **A primeira tentativa de login pode demorar entre 1 e 2 minutos** para responder enquanto a nuvem "acorda" a aplicação Java. Após o primeiro acesso, o aplicativo responderá instantaneamente.

## 🛠️ Tecnologias Utilizadas
* Flutter & Dart
* Gerenciamento de Estado Nativo / Services assíncronos
* Persistência local de Token com `shared_preferences`
* Comunicação HTTP segura com cabeçalhos `Bearer Token`

## 🚀 Como Rodar o Projeto
1. Certifique-se de ter o Flutter SDK instalado.
2. Clone este repositório.
3. No terminal da pasta do projeto, instale as dependências:
   ```bash
   flutter pub get