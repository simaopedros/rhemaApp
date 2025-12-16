# Checklist de Configuração Firebase (RHEMA)

Para que o login com Google funcione, você precisa configurar o projeto no Firebase Console.

## 1. Criar Projeto no Firebase
1. Acesse [console.firebase.google.com](https://console.firebase.google.com/).
2. Crie um novo projeto "Rhema App".
3. Desative o Google Analytics (opcional, simplifica).

## 2. Configurar App Android
1. No painel do projeto, clique no ícone do **Android** para adicionar um app.
2. **Nome do pacote**: `com.rhema.rhema_app` (Igual ao `android/app/build.gradle`).
3. **Apelido**: Rhema Mobile.
4. **Certificado de assinatura de depuração SHA-1**:
   - Abra o terminal na pasta `mobile/android`.
   - Rode: `./gradlew signingReport` (Windows: `gradlew signingReport`).
   - Copie o SHA-1 listado em `Task :app:signingReport` -> `Variant: debug` -> `SHA1`.
   - Cole no console do Firebase.

## 3. Baixar Arquivo de Configuração
1. Baixe o arquivo `google-services.json`.
2. Mova este arquivo para a pasta: `mobile/android/app/google-services.json`.

## 4. Ativar Autenticação
1. No menu lateral do Firebase, vá em **Criação** > **Authentication**.
2. Clique em **Vamos começar**.
3. Na aba **Sign-in method**, selecione **Google**.
4. Ative o switch "Ativar".
5. Defina o nome do projeto e email de suporte.
6. Salve.

## 5. Configurar iOS (Se for compilar para iPhone)
1. Adicione app iOS no Firebase (`com.rhema.rhema_app`).
2. Baixe `GoogleService-Info.plist`.
3. Adicione via Xcode na raiz do projeto `ios/Runner`.

## 6. Sincronizar Tudo
1. Após colocar o arquivo json, pare a execução do app (se estiver rodando).
2. Rode `flutter clean`.
3. Rode `flutter pub get`.
4. Rode `flutter run`.
