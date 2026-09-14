# Nubank Dashboard em TSX

Conversão do dashboard HTML original para React + TypeScript + Vite, preservando a interface mobile escura e os textos principais.

## Desenvolvimento

```bash
npm install
npm run dev
```

## Validação e build

```bash
npm run check
npm run build
npm run preview
```

O diretório `dist` é gerado pelo Vite e o projeto pode ser importado diretamente na Vercel. Não é necessário configurar servidor ou variável de ambiente.

## Edição dos campos

Toque no nome, saldo, fatura, limite ou empréstimo. Cada ação abre um campo de formulário real com foco automático, `inputMode` apropriado para celular e teclado funcional. Os valores são persistidos no `localStorage`.

## Instalação como app

O projeto inclui `manifest.webmanifest`, ícone, `display: standalone` e service worker. Em um navegador compatível, use **Adicionar à tela inicial** para abrir sem a barra de busca do navegador.

> O conteúdo visual e as referências de marca foram mantidos conforme o material fornecido pelo usuário. O repositório não inclui funcionalidades bancárias reais, autenticação ou transações.
