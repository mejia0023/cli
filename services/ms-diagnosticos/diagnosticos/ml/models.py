"""Modelos de IA/ML para diagnostico por imagen (scikit-learn).

- SUPERVISADO   : RandomForestClassifier -> clasifica la imagen (normal/anomalo) + confianza.
- NO SUPERVISADO: IsolationForest        -> detecta imagenes atipicas (anomalias) + confianza.

Ambos se entrenan al importar con IMAGENES sinteticas (limpias vs ruidosas) procesadas
por el MISMO pipeline de features que la inferencia, para que el espacio de caracteristicas
sea consistente. La API (predict_supervisado / predict_no_supervisado) esta pensada para
cambiar el modelo por uno entrenado con datos reales (o un CNN PyTorch/TensorFlow) sin
tocar las vistas.
"""
import io

import numpy as np
from PIL import Image
from sklearn.ensemble import IsolationForest, RandomForestClassifier

MODELO_VERSION = 'demo-sklearn-2'
_RNG = np.random.RandomState(42)
_LABELS = {0: 'normal', 1: 'anomalo'}
_SIZE = 32


def _features_from_array(arr01: np.ndarray) -> np.ndarray:
    """10 features de una imagen 32x32 en [0,1]: media, desviacion y histograma de 8 bins."""
    arr01 = np.clip(arr01, 0.0, 1.0)
    hist, _ = np.histogram(arr01, bins=8, range=(0.0, 1.0))
    hist = hist.astype(np.float64)
    hist = hist / (hist.sum() + 1e-9)
    return np.concatenate([[float(arr01.mean()), float(arr01.std())], hist])


def _features_from_image(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert('L').resize((_SIZE, _SIZE))
    arr = np.asarray(img, dtype=np.float64) / 255.0
    return _features_from_array(arr)


def _gen_normal() -> np.ndarray:
    """Imagen 'normal': intensidad homogenea, poca varianza (estudio limpio)."""
    base = _RNG.uniform(0.4, 0.7)
    noise = _RNG.uniform(0.0, 0.08)
    arr = base + _RNG.normal(0.0, noise, (_SIZE, _SIZE))
    return _features_from_array(arr)


def _gen_anomalo() -> np.ndarray:
    """Imagen 'anomala': ruido fuerte o alta varianza (artefactos/hallazgos)."""
    if _RNG.rand() < 0.5:
        arr = _RNG.uniform(0.0, 1.0, (_SIZE, _SIZE))
    else:
        base = _RNG.uniform(0.2, 0.8)
        arr = base + _RNG.normal(0.0, _RNG.uniform(0.2, 0.4), (_SIZE, _SIZE))
    return _features_from_array(arr)


def _train():
    n = 300
    x_normal = np.array([_gen_normal() for _ in range(n)])
    x_anomalo = np.array([_gen_anomalo() for _ in range(n)])
    x = np.vstack([x_normal, x_anomalo])
    y = np.array([0] * n + [1] * n)

    clf = RandomForestClassifier(n_estimators=100, random_state=42).fit(x, y)
    # IsolationForest se entrena SOLO con "normal": lo demas es atipico.
    iso = IsolationForest(random_state=42, contamination=0.1).fit(x_normal)
    return clf, iso


_CLF, _ISO = _train()


def predict_supervisado(image_bytes: bytes) -> dict:
    f = _features_from_image(image_bytes).reshape(1, -1)
    proba = _CLF.predict_proba(f)[0]
    idx = int(np.argmax(proba))
    return {
        'modo': 'SUPERVISADO',
        'hallazgo': _LABELS[idx],
        'confianza': round(float(proba[idx]), 4),
        'modelo_version': MODELO_VERSION,
    }


def predict_no_supervisado(image_bytes: bytes) -> dict:
    f = _features_from_image(image_bytes).reshape(1, -1)
    score = float(_ISO.decision_function(f)[0])  # >0 inlier, <0 outlier
    is_outlier = int(_ISO.predict(f)[0]) == -1
    confianza = round(float(1.0 / (1.0 + np.exp(-abs(score) * 8.0))), 4)
    return {
        'modo': 'NO_SUPERVISADO',
        'hallazgo': 'atipico' if is_outlier else 'tipico',
        'confianza': confianza,
        'modelo_version': MODELO_VERSION,
    }


def predict(image_bytes: bytes, modo: str = 'SUPERVISADO') -> dict:
    modo = (modo or 'SUPERVISADO').upper()
    if modo == 'NO_SUPERVISADO':
        return predict_no_supervisado(image_bytes)
    return predict_supervisado(image_bytes)
