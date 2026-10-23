# reddit-mcp Docker container

`reddit-mcp`'yi standalone streamable-http MCP container'ı olarak çalıştırır
(fonlar-mcp / spectre-mcp / tradingview-mcp ile aynı desen).

## Mimari

- Sunucu modülü: `python -m reddit_mcp.server`
- Stdio modu korunur (`REDDIT_MCP_TRANSPORT=stdio`); container varsayılanı
  `streamable-http`.
- Endpoint: `http://<host>:<port>/mcp`

## Kimlik / Session

Reddit tarafı kimlik bilgisini **environment değişkenlerinden** okur (API key
yok, cookie tabanlı). İmaja hiçbir session dosyası gömülmez ya da volume
mount edilmez; docker compose `.env` içindeki iki değişkeni container'a
geçirir:

```
REDDIT_SESSION_COOKIE=<reddit_session cookie değeri>
REDDIT_USERNAME=<reddit_kullanici_adi>
```

Cookie'yi almak için: tarayıcıda Reddit'e giriş yap → DevTools (F12) →
Application → Cookies → reddit.com → `reddit_session` değerini kopyala.
Alternatif olarak host üzerinde `reddit auth` çalıştırıp üretilen
`session.json` içinden bu iki değeri okuyabilirsin.

Not: Container dışında (stdio / yerel kullanım) dosya tabanlı okuma hâlâ
desteklenir — env var tanımlı değilse `REDDIT_SESSION_DIR` altında
`session.json`, sonra `settings.json` aranır.

## Hızlı başlangıç

```bash
cp .env.example .env
# .env içinde REDDIT_SESSION_COOKIE ve REDDIT_USERNAME'i doldur
docker compose up -d --build
```

Varsayılan port `8000`; değiştirmek için `.env` içinde `REDDIT_MCP_PORT`.

## Smoke test

```bash
# initialize (session id başlığını yakala)
curl -si -X POST http://localhost:8000/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}'

# tools/list (aynı mcp-session-id ile)
curl -s -X POST http://localhost:8000/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H 'mcp-session-id: <SESSION_ID>' \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
```

## OpenClaw registry kaydı

```json
"reddit-mcp": {
  "transport": "streamable-http",
  "url": "http://192.168.2.10:<port>/mcp"
}
```

sonra:

```bash
openclaw config validate
openclaw mcp probe reddit-mcp
```

## LAN / DNS-rebinding notu

MCP 1.x transport güvenliği varsayılan olarak localhost dışı Host
header'larını `421 Misdirected Request` ile reddeder. Container LAN IP
üzerinden erişileceği için server varsayılan olarak bu korumayı kapatır
(`REDDIT_MCP_NO_DNS_PROTECTION=1`). Sıkılaştırmak istersen `0` yap; o zaman
yalnızca localhost erişimi çalışır.

## Önemli güvenlik notu

Write tool'ları (`reddit_comment`, `reddit_submit`, `reddit_vote`,
`reddit_delete`, `reddit_inbox`) kimlik gerektirir ve Reddit ToS'a aykırı
otomasyon riski taşır — hesap ban riski vardır. Read-only kullanım kimlik
gerektirmez ama mevcut Reddit kısıtlamaları nedeniyle giriş cookie'si
olmadan bazı `.json` uçları 403 dönebilir.
