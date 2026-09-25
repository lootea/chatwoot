# Cuándo forkear vs configurar

Forkear solo si hay que **cambiar código fuente** y no existe vía de plugin, provisioning, config o API. Un fork es deuda: sync, CVEs y una imagen propia.

## Preguntas (en orden)

1. ¿Se resuelve 100% con config, env, provisioning, plugin o API pública?
2. ¿El vendor publica imagen usable y el cambio es de *cómo se corre*, no de *qué hace el binario*?
3. ¿Vamos a mantener el parche en cada release estable + CVE?

Si 1 o 2 es sí → **no fork**. Si 3 es no → tampoco.

## Decisión: Grafana — no forkear

Grafana se evaluó y se descartó.

La personalización que necesitamos (datasources, dashboards, alertas, contact points Slack, branding menor de instancia) se hace **100% vía provisioning/config**, ya versionada:

| Qué | Dónde | Imagen |
|---|---|---|
| Grafana central (tools) | `lootea-observability/grafana/provisioning/` | `grafana/grafana` oficial, pinneada |
| Grafana local (dev) | `lootea-backend/docker/grafana/provisioning/` | `grafana/grafana` oficial, pinneada |

El VPS tools **solo hace pull** de la imagen oficial. No hay repo `lootea/grafana` ni parche al binario. Un bump de versión es un PR de pin + smoke de dashboards/alertas.

## Decisión: Chatwoot — sí forkear

Hace falta imagen y deploy propios (self-hosted en tools, no el SaaS). Aunque hoy **no hay parches de producto**, el compose oficial pinnea `chatwoot/chatwoot:latest` y el publish de Docker Hub es de Chatwoot Inc. El fork existe para:

- construir **nuestra** imagen y publicarla en el registry Lootea (`lootea/chatwoot`);
- desplegar en tools con pull + smoke + rollback;
- no depender de `latest` ni de un build en el servidor.

Si en el futuro un cambio se puede hacer por `.env`, Super Admin o API, **no se parchea el árbol**. Ver [diff.md](diff.md).

## Plantilla para la próxima herramienta

| Campo | Grafana | Chatwoot | (siguiente) |
|---|---|---|---|
| ¿Hay que tocar el source? | No | Solo si un feature no existe vía API/config | |
| ¿Imagen oficial sirve? | Sí | Sí, pero no la usamos: queremos registry + tags propios | |
| ¿Config ya está en git? | Sí (`*/grafana/provisioning`) | `.env` en tools; overlay `docker-compose.lootea.yml` | |
| Decisión | **No fork** | **Fork** + proceso de sync | |
| Imagen | pull oficial | CI → ECR `lootea/chatwoot` → tools pull | |

Cerrar la evaluación en una fila de esta tabla (o un PR de una página) **antes** de clonar el repo upstream.
