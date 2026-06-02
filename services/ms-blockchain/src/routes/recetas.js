const express = require('express');
const blockchain = require('../services/blockchainService');
const auth = require('../middleware/auth');

const router = express.Router();

/**
 * POST /recetas
 * body: { documentoTexto, pacienteId, medicoUid }
 * Solo MEDICO o ADMINISTRADOR
 */
router.post('/', auth({ roles: ['MEDICO', 'ADMINISTRADOR'] }), async (req, res) => {
  try {
    const { documentoTexto, pacienteId, medicoUid } = req.body || {};
    if (!documentoTexto || !pacienteId || !medicoUid) {
      return res.status(400).json({ error: 'Faltan documentoTexto/pacienteId/medicoUid' });
    }
    const result = await blockchain.registrar(documentoTexto, pacienteId, medicoUid);
    res.json(result);
  } catch (e) {
    console.error('Error en POST /recetas:', e);
    res.status(500).json({ error: e.message });
  }
});

/**
 * GET /recetas/verificar?hash=...
 * Cualquier rol autenticado.
 */
router.get('/verificar', auth(), async (req, res) => {
  const { hash } = req.query;
  console.log(`[verificar] hash recibido: "${hash}" (len=${(hash || '').length})`);
  try {
    if (!hash) return res.status(400).json({ error: 'Falta query param ?hash=' });
    const result = await blockchain.verificarPorHash(String(hash));
    console.log(`[verificar] resultado:`, result);
    res.json(result);
  } catch (e) {
    console.error('Error en GET /recetas/verificar:', e.message);
    // Si fallo por hash mal formado o contrato, devolvemos exists=false con razon
    // en lugar de 500 — el frontend lo trata mejor.
    res.json({ exists: false, error: e.message });
  }
});

/**
 * GET /recetas/paciente/:id
 * Roles permitidos por defecto, sin filtro adicional aqui (ms-gestion ya filtra).
 */
router.get('/paciente/:id', auth(), async (req, res) => {
  try {
    const indices = await blockchain.recetasDe(req.params.id);
    res.json({ pacienteId: req.params.id, indices });
  } catch (e) {
    console.error('Error en GET /recetas/paciente/:id:', e);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
