import React from 'react';
import { View, Text, FlatList, ActivityIndicator, StyleSheet, RefreshControl } from 'react-native';
import { useQuery } from '@apollo/client';
import { MIS_FACTURAS_PACIENTE } from '../graphql/queries';

export function MisFacturasScreen() {
  const { data, loading, error, refetch } = useQuery<any>(MIS_FACTURAS_PACIENTE, {
    fetchPolicy: 'cache-and-network',
  });

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

  const facturas: any[] = data?.misFacturas ?? [];

  return (
    <FlatList
      data={facturas}
      keyExtractor={f => f.id}
      contentContainerStyle={{ padding: 12 }}
      refreshControl={<RefreshControl refreshing={loading} onRefresh={() => refetch()} tintColor="#0f6e56" />}
      ListEmptyComponent={
        <View style={styles.center}>
          <Text style={styles.empty}>No tienes facturas.</Text>
        </View>
      }
      renderItem={({ item }) => (
        <View style={styles.card}>
          <View style={styles.headerRow}>
            <Text style={styles.numero}>{item.numero}</Text>
            <Text style={styles.total}>Bs {item.total}</Text>
          </View>
          <View style={styles.metaRow}>
            <Text style={styles.meta}>{new Date(item.fecha).toLocaleDateString()}</Text>
            <Text style={styles.meta}>{item.metodoPago}</Text>
            <View style={[styles.badge, item.estado === 'PAGADA' ? styles.bgGreen : styles.bgGray]}>
              <Text style={styles.badgeText}>{item.estado}</Text>
            </View>
          </View>
          {item.detalles?.map((d: any, i: number) => (
            <Text key={i} style={styles.detalle}>
              • {d.medicamento.nombre} × {d.cantidad} = Bs {d.subtotal}
            </Text>
          ))}
        </View>
      )}
    />
  );
}

const styles = StyleSheet.create({
  center: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 40 },
  empty: { color: '#6b7280', fontSize: 14, textAlign: 'center' },
  error: { color: '#a32d2d', fontSize: 14, textAlign: 'center' },
  card: { backgroundColor: 'white', borderRadius: 8, padding: 16, marginBottom: 10 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  numero: { fontSize: 16, fontWeight: '700', color: '#1f2937' },
  total: { fontSize: 18, fontWeight: '700', color: '#0f6e56' },
  metaRow: { flexDirection: 'row', alignItems: 'center', marginTop: 6, gap: 12 },
  meta: { fontSize: 12, color: '#6b7280' },
  badge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 3, marginLeft: 'auto' },
  bgGreen: { backgroundColor: '#d1fae5' },
  bgGray: { backgroundColor: '#e5e7eb' },
  badgeText: { fontSize: 10, fontWeight: '700', color: '#065f46' },
  detalle: { fontSize: 13, color: '#4b5563', marginTop: 4 },
});
