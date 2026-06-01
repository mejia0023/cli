import React from 'react';
import { View, Text, FlatList, ActivityIndicator, StyleSheet, Linking, TouchableOpacity, RefreshControl } from 'react-native';
import { useQuery } from '@apollo/client';
import { useAuth } from '../auth/AuthContext';
import { MIS_RECETAS_PACIENTE, MIS_RECETAS_MEDICO } from '../graphql/queries';

export function MisRecetasScreen() {
  const { user } = useAuth();
  const esPaciente = user?.rol === 'PACIENTE';
  const query = esPaciente ? MIS_RECETAS_PACIENTE : MIS_RECETAS_MEDICO;
  const { data, loading, error, refetch } = useQuery<any>(query, { fetchPolicy: 'cache-and-network' });

  if (loading && !data) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color="#0f6e56" />
      </View>
    );
  }

  if (error && !data) {
    return (
      <View style={styles.center}>
        <Text style={styles.error}>Error: {error.message}</Text>
      </View>
    );
  }

  const recetas: any[] = esPaciente ? data?.misRecetasPaciente ?? [] : data?.misRecetas ?? [];

  return (
    <FlatList
      data={recetas}
      keyExtractor={r => r.id}
      contentContainerStyle={{ padding: 12 }}
      refreshControl={<RefreshControl refreshing={loading} onRefresh={() => refetch()} tintColor="#0f6e56" />}
      ListEmptyComponent={
        <View style={styles.center}>
          <Text style={styles.empty}>No tienes recetas {esPaciente ? 'registradas' : 'emitidas'}.</Text>
        </View>
      }
      renderItem={({ item }) => (
        <View style={styles.card}>
          <View style={styles.headerRow}>
            <Text style={styles.title}>
              {esPaciente
                ? `Dr. ${item.medicoNombre}`
                : `${item.paciente?.nombre ?? ''} ${item.paciente?.apellido ?? ''}`}
            </Text>
            <Text style={styles.date}>{new Date(item.fechaEmision).toLocaleDateString()}</Text>
          </View>

          <View style={styles.badges}>
            {item.controlado && <Badge text="Controlado" color="#fee2e2" textColor="#991b1b" />}
            {item.blockchainTx ? (
              <Badge text="On-chain" color="#d1fae5" textColor="#065f46" />
            ) : item.controlado ? (
              <Badge text="Pendiente blockchain" color="#fef3c7" textColor="#92400e" />
            ) : null}
            <Badge text={item.estado} color="#e0e7ff" textColor="#3730a3" />
          </View>

          {esPaciente && item.diagnostico && (
            <Text style={styles.diag}>{item.diagnostico}</Text>
          )}

          {item.detalles?.map((d: any, i: number) => (
            <Text key={i} style={styles.detalle}>
              • {d.medicamento.nombre} × {d.cantidad}
              {d.posologia ? ` — ${d.posologia}` : ''}
            </Text>
          ))}

          {item.blockchainTx && (
            <TouchableOpacity
              onPress={() => Linking.openURL(`https://amoy.polygonscan.com/tx/${item.blockchainTx}`)}
              style={styles.txLink}
            >
              <Text style={styles.txText}>Ver tx: {item.blockchainTx.substring(0, 18)}…</Text>
            </TouchableOpacity>
          )}
        </View>
      )}
    />
  );
}

function Badge({ text, color, textColor }: { text: string; color: string; textColor: string }) {
  return (
    <View style={[styles.badge, { backgroundColor: color }]}>
      <Text style={[styles.badgeText, { color: textColor }]}>{text}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 40 },
  empty: { color: '#6b7280', fontSize: 14, textAlign: 'center' },
  error: { color: '#a32d2d', fontSize: 14, textAlign: 'center' },
  card: { backgroundColor: 'white', borderRadius: 8, padding: 16, marginBottom: 10 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  title: { fontSize: 15, fontWeight: '600', color: '#1f2937', flex: 1 },
  date: { fontSize: 11, color: '#6b7280' },
  badges: { flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 8, marginBottom: 8 },
  badge: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 4 },
  badgeText: { fontSize: 10, fontWeight: '700' },
  diag: { fontSize: 13, color: '#4b5563', marginBottom: 8, fontStyle: 'italic' },
  detalle: { fontSize: 13, color: '#1f2937', marginTop: 2 },
  txLink: { marginTop: 8, paddingTop: 8, borderTopWidth: 1, borderTopColor: '#f3f4f6' },
  txText: { fontSize: 11, color: '#0f6e56' },
});
