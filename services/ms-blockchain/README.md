# ms-blockchain — Registro inmutable de recetas (Polygon Amoy)

Microservicio Node.js que expone una API REST para registrar y verificar recetas médicas en la blockchain pública de Polygon Amoy (testnet).

## Stack

- **Node.js 18+** + Express
- **Solidity 0.8.20** + Hardhat
- **ethers.js v6** para interactuar con la red
- **Polygon Amoy** como red destino (chainId 80002)
- **Supabase JWT** (JWKS asimétrico, mismo proyecto que ms-gestion) para autorizar

## Endpoints

| Método | Ruta | Auth (rol) | Función |
|---|---|---|---|
| POST | `/recetas` | MEDICO / ADMINISTRADOR | Calcula SHA-256 del documento canónico y lo registra on-chain |
| GET  | `/recetas/verificar?hash=...` | Cualquier rol | Verifica existencia de un hash en el contrato |
| GET  | `/recetas/paciente/:id` | Cualquier rol | Devuelve índices de registros del paciente |
| GET  | `/health` | abierto | Status del servicio + red + contrato |

## Setup local

```powershell
cd services\ms-blockchain
npm install
npx hardhat compile

# Tests del contrato (red en memoria de Hardhat)
npx hardhat test

# === Opcion A — desarrollo 100% local ===
# 1. Levantar nodo Hardhat local en otra terminal:
npx hardhat node
# 2. Desplegar contrato a la red local:
npx hardhat run scripts/deploy.js --network localhost
# 3. Copiar address devuelta al .env como CONTRACT_ADDRESS
# 4. Configurar AMOY_RPC_URL=http://127.0.0.1:8545 y PRIVATE_KEY (Hardhat node imprime accounts al arrancar)
# 5. Arrancar el server:
node src/server.js
```

## Setup contra Polygon Amoy (testnet)

```powershell
# 1. Obtener MATIC de testnet: https://faucet.polygon.technology
# 2. Copiar PRIVATE_KEY de tu wallet (NUNCA commitear)
# 3. Configurar .env:
#    AMOY_RPC_URL=https://rpc-amoy.polygon.technology
#    PRIVATE_KEY=0x...
#    POLYGONSCAN_API_KEY=... (opcional, para verify)
# 4. Desplegar:
npx hardhat run scripts/deploy.js --network amoy
# 5. La address se imprime y se guarda en deployments/amoy.json — copiarla a CONTRACT_ADDRESS
# 6. Arrancar server:
node src/server.js
```

El contrato debe quedar visible en https://amoy.polygonscan.com/address/<CONTRACT_ADDRESS>.

## Integración con ms-gestion

ms-gestion llama a `POST /recetas` cada vez que un médico emite una receta con un medicamento controlado (ver `RecetaService.emitir()` en ms-gestion). Si la llamada falla o expira (>5s), ms-gestion encola la receta y reintenta en background cada minuto (ver `RecetaService.reintentarBlockchainPendientes()`).

## Variables de entorno

Ver `.env.example`.
