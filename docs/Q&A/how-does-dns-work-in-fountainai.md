# How does DNS work in FountainAI, and how do I configure the host to use my TLD?

FountainAI embeds its own authoritative DNS server within the gateway. Zones are stored in `Configuration/zones.yml` and managed by an actor-based `ZoneManager`. The `GatewayApp` streams updates to an in-memory `DNSEngine` that answers UDP/TCP queries when started with `--dns`.

## Domain & zone delegation

The `fountain.coach` TLD is registered in Route53, with zone records handled via Hetzner's DNS API. To delegate the internal zone, export `HETZNER_API_TOKEN` and `HETZNER_ZONE_ID`, run `scripts/delegate-internal-zone.sh`, and verify `internal.fountain.coach` using `dig`.

## Service endpoints & OpenAPI configuration

OpenAPI specs already point at subdomains like:

- `http://dns.fountain.coach/api/v1`
- `https://gateway.fountain.coach/api/v1`

To change the public hostname, edit each spec's `servers` section and the runtime config in `Configuration/gateway.yml`.

## Certificates & automation

TLS certificates are renewed with `scripts/renew-certs.sh`. This script uses a DNS-01 challenge via the internal DNS API (`dns-api-hook.sh`), defaulting to `dns.fountain.coach` and the `internal.fountain.coach` zone.

## Local development

For local setups:

1. Run the embedded DNS (`swift run GatewayApp --dns`) and populate `Configuration/zones.yml` with records mapping subdomains such as `gateway.fountain.coach` to your local machine.
2. Alternatively, add those subdomains to `/etc/hosts` if you don't run DNS locally.
3. Override environment variables like `DNS_API` and `DNS_ZONE` to point at local aliases when testing.

Following this approach keeps services reachable under `*.fountain.coach` in production while allowing local aliases during development.

