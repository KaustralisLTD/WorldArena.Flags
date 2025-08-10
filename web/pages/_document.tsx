import { Html, Head, Main, NextScript } from 'next/document'

export default function Document() {
  return (
    <Html lang="ru">
      <Head>
        {/* Favicon */}
        <link rel="icon" href="/favicon.ico" />
        <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
        <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
        <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
        <link rel="manifest" href="/manifest.json" />
        
        {/* Theme color */}
        <meta name="theme-color" content="#6366f1" />
        <meta name="msapplication-TileColor" content="#6366f1" />
        
        {/* Preconnect to external domains */}
        <link rel="preconnect" href="https://flagcdn.com" />
        <link rel="preconnect" href="https://restcountries.com" />
        
        {/* DNS prefetch */}
        <link rel="dns-prefetch" href="https://flagcdn.com" />
        <link rel="dns-prefetch" href="https://restcountries.com" />
      </Head>
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  )
} 