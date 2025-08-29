# Node 22.11+ required by CitrineOS repos
FROM node:22.11-slim

# tools + CA bundle for TLS
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

ARG CORE_REF=main

# 1) copy OCPI workspace
WORKDIR /app
COPY . .

# 2) clone CORE where TS refs expect it
RUN git clone --depth 1 --branch ${CORE_REF} https://github.com/citrineos/citrineos-core /citrineos-core

# 3) install deps for CORE (has package-lock.json -> use npm ci)
WORKDIR /citrineos-core
RUN npm ci

# 4) install deps for OCPI (no lockfile -> use npm install)
WORKDIR /app
RUN npm install --no-audit --no-fund

# 5) build OCPI (tsc builds refs into /citrineos-core too)
RUN npm run build

# 6) run OCPI server (Swagger default :8085)
EXPOSE 8085
WORKDIR /app/Server
CMD ["sh","-lc","node -e \"console.log('AMQP=',process.env.CITRINEOS_UTIL_MESSAGEBROKER_AMQP_URL||process.env.CITRINEOS_util_messageBroker_amqp_url)\" && node dist/index.js"]