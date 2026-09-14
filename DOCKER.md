# reddit-mcp Docker container

`reddit-mcp`'yi standalone streamable-http MCP container'ı olarak çalıştırır
(fonlar-mcp / spectre-mcp / tradingview-mcp ile aynı desen).

## Mimari

- Sunucu modülü: `python -m reddit_mcp.server`
- Stdio modu korunur (`REDDIT_MCP_TRANSPORT=stdio`); container varsayılanı
  `streamable-http`.
- Endpoint: `http://<host>:<port>/mcp`

## Kimlik / Session

Reddit tarafı kimlik bilgisini **session dosyasından** okur (API key yok,
cookie tabanlı). Container'a bir volume mount edilir ve `.env` içindeki

```
REDDIT_SESSION_DIR=/data
```

değişkeni bu mount noktasını gösterir. Server başlarken bu klasörde önce
`session.json`, bulunamazsa `settings.json` aranır — ikisinin de içerik
formatı aynıdır:

```json
{
  "cookies": { "reddit_session": "...", "...": "..." },
  "username": "<reddit_kullanici_adi>",
  "saved_at": 0,
  "browser": "firefox"   // opsiyonel
}
```

Dosyayı host tarafında oluşturmak için (tarayıcıdan import):

```bash
# host üzerinde, session klasörüne:
reddit auth                  # tarayıcıdan cookie import eder, session.json yazar
# veya mevcut bir dosyayı kopyala:
cp /path/to/session.json ./session/session.json
```

`settings.json` adıyla vermek istersen aynı içerikle
`./session/settings.json` kullan.

## Hızlı başlangıç

```bash
cp .env.example .env
# .env içinde REDDIT_SESSION_HOST_DIR'i session dosyasının olduğu klasöre ayarla
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
