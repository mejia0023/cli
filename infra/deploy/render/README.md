# Despliegue Render — ms-blockchain

Render ofrece un Web Service gratuito ideal para Node.js. Polygon Amoy es la testnet final.

## Paso 1 — Desplegar contrato a Polygon Amoy

```powershell
cd services\ms-blockchain

# 1. Obtener MATIC del faucet:
#    https://faucet.polygon.technology (Polygon Amoy)
#    minimo 0.5 MATIC en la wallet asociada a PRIVATE_KEY

# 2. Configurar .env con:
#    AMOY_RPC_URL=https://rpc-amoy.polygon.technology
#    PRIVATE_KEY=0x...
#    POLYGONSCAN_API_KEY=...  (opcional, para verify)

npx hardhat compile
npx hardhat run scripts/deploy.js --network amoy

# La address se imprime y se guarda en deployments/amoy.json
# Copiarla — la necesitas en el siguiente paso
```

Verificar en https://amoy.polygonscan.com/address/<CONTRACT_ADDRESS>.

## Paso 2 — Configurar Render

1. Crear cuenta en https://render.com (gratis).
2. New → Web Service → conectar el repo de GitHub.
3. Root Directory: `services/ms-blockchain`.
4. Build Command: `npm install && npx hardhat compile`.
5. Start Command: `node src/server.js`.
6. Environment variables:
   - `PORT=10000`
   - `AMOY_RPC_URL=https://rpc-amoy.polygon.technology`
   - `PRIVATE_KEY=0x...` (la misma que usaste para deploy)
   - `CONTRACT_ADDRESS=<address devuelto en paso 1>`
   - `SUPABASE_JWKS_URI=https://<tu-proyecto>.supabase.co/auth/v1/.well-known/jwks.json`
   - `CORS_ORIGINS=https://<azure-app-service>.azurewebsites.net,https://<static-web-app>.azurestaticapps.net`
7. Click "Create Web Service".

URL final: `https://ms-blockchain-clinica-xxxx.onrender.com`. Copiar a `BLOCKCHAIN_URL` en ms-gestion (Azure App Service settings).

## Verificación post-deploy

```powershell
# Health
curl https://ms-blockchain-clinica-xxxx.onrender.com/health

# Debe devolver:
# { "status":"OK", "service":"ms-blockchain", "chainId":80002, "contract":"0x..." }
```

## Coste

- Tier gratuito de Render: el servicio se duerme tras 15 min sin tráfico (~30s para despertar). Es aceptable para defensa del parcial.
- Si se requiere always-on: Starter $7/mes.
