const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');
const { sha256Hex, toBytes32 } = require('./hashService');

const ABI_PATH = path.join(__dirname, '..', '..', 'artifacts', 'contracts', 'RegistroRecetas.sol', 'RegistroRecetas.json');

class BlockchainService {
  constructor() {
    const rpcUrl = process.env.AMOY_RPC_URL || process.env.RPC_URL || 'http://127.0.0.1:8545';
    const privateKey = process.env.PRIVATE_KEY;
    const contractAddress = process.env.CONTRACT_ADDRESS;

    if (!contractAddress) {
      console.warn('CONTRACT_ADDRESS no definido — los endpoints de escritura fallaran');
    }
    if (!privateKey) {
      console.warn('PRIVATE_KEY no definido — los endpoints de escritura fallaran');
    }

    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.signer = privateKey ? new ethers.Wallet(privateKey, this.provider) : null;
    this.contractAddress = contractAddress;
    this.rpcUrl = rpcUrl;

    const artifact = fs.existsSync(ABI_PATH) ? JSON.parse(fs.readFileSync(ABI_PATH, 'utf8')) : null;
    if (!artifact) {
      console.warn('Artifact del contrato no encontrado — ejecuta `npx hardhat compile`');
    }
    this.abi = artifact ? artifact.abi : [];

    this.contract = contractAddress && this.abi.length > 0
      ? new ethers.Contract(contractAddress, this.abi, this.signer ?? this.provider)
      : null;
  }

  ready() {
    return Boolean(this.contract);
  }

  /**
   * Registra un documento canonico (string) en el contrato.
   * Devuelve { id, txHash, blockNumber, hash }.
   */
  async registrar(documentoTexto, pacienteId, medicoUid) {
    if (!this.contract || !this.signer) throw new Error('Blockchain no listo: faltan CONTRACT_ADDRESS o PRIVATE_KEY');

    const hashHex = sha256Hex(documentoTexto);
    const hashBytes32 = '0x' + hashHex;
    const pacienteBytes32 = toBytes32(pacienteId, ethers);
    const medicoBytes32 = toBytes32(medicoUid, ethers);

    const tx = await this.contract.registrar(hashBytes32, pacienteBytes32, medicoBytes32);
    const receipt = await tx.wait(1);

    // Extraer id del evento RecetaRegistrada
    let registeredId = null;
    for (const log of receipt.logs) {
      try {
        const parsed = this.contract.interface.parseLog(log);
        if (parsed && parsed.name === 'RecetaRegistrada') {
          registeredId = Number(parsed.args[0]);
          break;
        }
      } catch (_) { /* otro log */ }
    }

    return {
      id: registeredId,
      txHash: receipt.hash,
      blockNumber: receipt.blockNumber,
      hash: hashHex
    };
  }

  async verificarPorHash(hashHex) {
    if (!this.contract) throw new Error('Blockchain no listo');
    const hashBytes32 = hashHex.startsWith('0x') ? hashHex : ('0x' + hashHex);
    const [exists, id, timestamp] = await this.contract.verificar(hashBytes32);
    return { exists, id: Number(id), timestamp: Number(timestamp) };
  }

  async recetasDe(pacienteId) {
    if (!this.contract) throw new Error('Blockchain no listo');
    const pacienteBytes32 = toBytes32(pacienteId, ethers);
    const indices = await this.contract.recetasDe(pacienteBytes32);
    return indices.map(i => Number(i));
  }

  async networkInfo() {
    const net = await this.provider.getNetwork();
    return {
      chainId: Number(net.chainId),
      name: net.name,
      rpcUrl: this.rpcUrl,
      contract: this.contractAddress,
      signer: this.signer ? await this.signer.getAddress() : null
    };
  }
}

module.exports = new BlockchainService();
