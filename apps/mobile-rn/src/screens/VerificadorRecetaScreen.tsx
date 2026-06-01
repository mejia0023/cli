import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, ScrollView } from 'react-native';
import { useLazyQuery } from '@apollo/client';
import { VERIFICAR_RECETA } from '../graphql/queries';

export function VerificadorRecetaScreen() {
  const [recetaId, setRecetaId] = useState('');
  const [verificar, { data, loading, error }] = useLazyQuery(VERIFICAR_RECETA, {
    fetchPolicy: 'network-only',
  });

  function onVerificar() {
    if (recetaId.trim().length < 36) return;
    verificar({ variables: { id: recetaId.trim() } });
  }

  const resultado: any = data?.verificarReceta;

  return (
    <ScrollView style={styles.wrap} contentContainerStyle={{ padding: 16 }}>
      <Text style={styles.title}>Verificar receta en blockchain</Text>
      <Text style={styles.subtitle}>
        Pega el UUID de una receta para verificar si esta registrada inmutablemente on-chain.
      </Text>

      <TextInput
        value={recetaId}
        onChangeText={setRecetaId}
        placeholder="UUID de la receta (36 caracteres)"
        autoCapitalize="none"
        autoCorrect={false}
        style={styles.input}
      />

      <TouchableOpacity
        onPress={onVerificar}
        disabled={loading || recetaId.length < 36}
        style={[styles.btn, (loading || recetaId.length < 36) && styles.btnDisabled]}
      >
        <Text style={styles.btnText}>{loading ? 'Verificando...' : 'Verificar on-chain'}</Text>
      </TouchableOpacity>

      {loading && <ActivityIndicator color="#0f6e56" style={{ marginTop: 16 }} />}

      {error && <Text style={styles.err}>✗ Error: {error.message}</Text>}

      {resultado && resultado.exists === true && (
        <View style={styles.ok}>
          <Text style={styles.okTitle}>✓ Receta registrada</Text>
          <Text style={styles.okItem}>Bloque: {resultado.blockNumber ?? '—'}</Text>
          <Text style={styles.okItem}>
            Timestamp: {resultado.timestamp ? new Date(resultado.timestamp * 1000).toLocaleString() : '—'}
          </Text>
          <Text style={styles.okItem}>ID on-chain: {resultado.id}</Text>
        </View>
      )}

      {resultado && resultado.exists === false && !resultado.error && (
        <View style={styles.warn}>
          <Text style={styles.warnTitle}>⚠ No registrada</Text>
          {resultado.razon && <Text style={styles.warnItem}>{resultado.razon}</Text>}
        </View>
      )}

      {resultado?.error && (
        <View style={styles.err2}>
          <Text style={styles.errTitle}>✗ Error</Text>
          <Text style={styles.errItem}>{resultado.error}</Text>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: '#f6f8fa' },
  title: { fontSize: 20, fontWeight: '700', color: '#0f6e56', marginBottom: 4 },
  subtitle: { fontSize: 13, color: '#6b7280', marginBottom: 20 },
  input: {
    backgroundColor: 'white', borderWidth: 1, borderColor: '#d1d5db',
    borderRadius: 6, padding: 12, fontSize: 13, fontFamily: 'monospace',
  },
  btn: { backgroundColor: '#0f6e56', borderRadius: 6, paddingVertical: 14, marginTop: 12, alignItems: 'center' },
  btnDisabled: { opacity: 0.5 },
  btnText: { color: 'white', fontWeight: '600' },
  ok: { backgroundColor: '#d1fae5', padding: 16, borderRadius: 8, marginTop: 16 },
  okTitle: { color: '#065f46', fontWeight: '700', fontSize: 15 },
  okItem: { color: '#065f46', fontSize: 13, marginTop: 4 },
  warn: { backgroundColor: '#fef3c7', padding: 16, borderRadius: 8, marginTop: 16 },
  warnTitle: { color: '#92400e', fontWeight: '700', fontSize: 15 },
  warnItem: { color: '#92400e', fontSize: 13, marginTop: 4 },
  err: { color: '#a32d2d', marginTop: 12, fontSize: 13 },
  err2: { backgroundColor: '#fee2e2', padding: 16, borderRadius: 8, marginTop: 16 },
  errTitle: { color: '#991b1b', fontWeight: '700', fontSize: 15 },
  errItem: { color: '#991b1b', fontSize: 13, marginTop: 4 },
});
