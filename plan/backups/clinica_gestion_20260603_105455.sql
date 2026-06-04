--
-- PostgreSQL database dump
--

\restrict pT8k8SBYejHLY6vMR9NBvorP2PrL788xhNYX1jrOUbiSYrMkxlj5Oc5IA3KIqWM

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: estado_factura_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_factura_enum AS ENUM (
    'PENDIENTE',
    'PAGADA',
    'ANULADA'
);


ALTER TYPE public.estado_factura_enum OWNER TO postgres;

--
-- Name: estado_receta_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.estado_receta_enum AS ENUM (
    'EMITIDA',
    'DISPENSADA',
    'ANULADA'
);


ALTER TYPE public.estado_receta_enum OWNER TO postgres;

--
-- Name: metodo_pago_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.metodo_pago_enum AS ENUM (
    'EFECTIVO',
    'TARJETA',
    'TRANSFERENCIA',
    'QR'
);


ALTER TYPE public.metodo_pago_enum OWNER TO postgres;

--
-- Name: tipo_movimiento_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.tipo_movimiento_enum AS ENUM (
    'ENTRADA',
    'SALIDA',
    'AJUSTE'
);


ALTER TYPE public.tipo_movimiento_enum OWNER TO postgres;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria (
    id integer NOT NULL,
    nombre character varying(80) NOT NULL,
    descripcion character varying(200)
);


ALTER TABLE public.categoria OWNER TO postgres;

--
-- Name: categoria_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_id_seq OWNER TO postgres;

--
-- Name: categoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categoria_id_seq OWNED BY public.categoria.id;


--
-- Name: detalle_factura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_factura (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    factura_id uuid NOT NULL,
    medicamento_id uuid NOT NULL,
    lote_id uuid NOT NULL,
    receta_id uuid,
    cantidad integer NOT NULL,
    precio_unitario numeric(12,2) NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    CONSTRAINT detalle_factura_cantidad_check CHECK ((cantidad > 0)),
    CONSTRAINT detalle_factura_precio_unitario_check CHECK ((precio_unitario >= (0)::numeric)),
    CONSTRAINT detalle_factura_subtotal_check CHECK ((subtotal >= (0)::numeric))
);


ALTER TABLE public.detalle_factura OWNER TO postgres;

--
-- Name: detalle_receta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.detalle_receta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    receta_id uuid NOT NULL,
    medicamento_id uuid NOT NULL,
    cantidad integer NOT NULL,
    posologia character varying(250),
    CONSTRAINT detalle_receta_cantidad_check CHECK ((cantidad > 0))
);


ALTER TABLE public.detalle_receta OWNER TO postgres;

--
-- Name: factura; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.factura (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    numero character varying(30) NOT NULL,
    paciente_id uuid,
    usuario_id uuid NOT NULL,
    fecha timestamp with time zone DEFAULT now() NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    descuento numeric(12,2) DEFAULT 0 NOT NULL,
    total numeric(12,2) NOT NULL,
    metodo_pago public.metodo_pago_enum NOT NULL,
    estado public.estado_factura_enum DEFAULT 'PAGADA'::public.estado_factura_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT factura_descuento_check CHECK ((descuento >= (0)::numeric)),
    CONSTRAINT factura_subtotal_check CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT factura_total_check CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.factura OWNER TO postgres;

--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE public.flyway_schema_history OWNER TO postgres;

--
-- Name: lote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lote (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    medicamento_id uuid NOT NULL,
    proveedor_id uuid,
    codigo_lote character varying(80) NOT NULL,
    fecha_vencimiento date NOT NULL,
    cantidad_inicial integer NOT NULL,
    cantidad_actual integer NOT NULL,
    precio_compra numeric(12,2) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT lote_cantidad_actual_check CHECK ((cantidad_actual >= 0)),
    CONSTRAINT lote_cantidad_inicial_check CHECK ((cantidad_inicial >= 0)),
    CONSTRAINT lote_precio_compra_check CHECK ((precio_compra >= (0)::numeric))
);


ALTER TABLE public.lote OWNER TO postgres;

--
-- Name: medicamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.medicamento (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(150) NOT NULL,
    descripcion text,
    categoria_id integer,
    precio_venta numeric(12,2) NOT NULL,
    requiere_receta boolean DEFAULT false NOT NULL,
    controlado boolean DEFAULT false NOT NULL,
    stock_minimo integer DEFAULT 0 NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT medicamento_precio_venta_check CHECK ((precio_venta >= (0)::numeric)),
    CONSTRAINT medicamento_stock_minimo_check CHECK ((stock_minimo >= 0))
);


ALTER TABLE public.medicamento OWNER TO postgres;

--
-- Name: movimiento_inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimiento_inventario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    lote_id uuid NOT NULL,
    tipo public.tipo_movimiento_enum NOT NULL,
    cantidad integer NOT NULL,
    motivo character varying(250),
    usuario_id uuid,
    fecha timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.movimiento_inventario OWNER TO postgres;

--
-- Name: paciente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.paciente (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supabase_uid character varying(100),
    ci character varying(20) NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    telefono character varying(30),
    email character varying(150),
    fecha_nacimiento date,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.paciente OWNER TO postgres;

--
-- Name: proveedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.proveedor (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre character varying(150) NOT NULL,
    nit character varying(30),
    telefono character varying(30),
    email character varying(150),
    direccion character varying(250),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.proveedor OWNER TO postgres;

--
-- Name: receta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.receta (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    paciente_id uuid NOT NULL,
    medico_nombre character varying(150) NOT NULL,
    medico_uid character varying(100) NOT NULL,
    diagnostico text,
    fecha_emision timestamp with time zone DEFAULT now() NOT NULL,
    controlado boolean DEFAULT false NOT NULL,
    hash_documento character varying(80),
    blockchain_tx character varying(100),
    blockchain_id bigint,
    estado public.estado_receta_enum DEFAULT 'EMITIDA'::public.estado_receta_enum NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.receta OWNER TO postgres;

--
-- Name: rol; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rol (
    id integer NOT NULL,
    nombre character varying(40) NOT NULL,
    descripcion character varying(200)
);


ALTER TABLE public.rol OWNER TO postgres;

--
-- Name: rol_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rol_id_seq OWNER TO postgres;

--
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rol_id_seq OWNED BY public.rol.id;


--
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supabase_uid character varying(100) NOT NULL,
    nombre character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    rol_id integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- Name: vw_inventario_critico; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_inventario_critico AS
 SELECT m.id AS medicamento_id,
    m.nombre AS medicamento,
    m.stock_minimo,
    COALESCE(sum(l.cantidad_actual), (0)::bigint) AS stock_actual,
        CASE
            WHEN (COALESCE(sum(l.cantidad_actual), (0)::bigint) = 0) THEN 'SIN_STOCK'::text
            WHEN (COALESCE(sum(l.cantidad_actual), (0)::bigint) <= m.stock_minimo) THEN 'CRITICO'::text
            WHEN (COALESCE(sum(l.cantidad_actual), (0)::bigint) <= (m.stock_minimo * 2)) THEN 'BAJO'::text
            ELSE 'OK'::text
        END AS nivel
   FROM (public.medicamento m
     LEFT JOIN public.lote l ON ((l.medicamento_id = m.id)))
  WHERE (m.activo = true)
  GROUP BY m.id, m.nombre, m.stock_minimo
  ORDER BY COALESCE(sum(l.cantidad_actual), (0)::bigint);


ALTER VIEW public.vw_inventario_critico OWNER TO postgres;

--
-- Name: vw_recetas_blockchain; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_recetas_blockchain AS
 SELECT (date_trunc('month'::text, fecha_emision))::date AS mes,
    count(*) AS total_recetas,
    count(blockchain_tx) AS registradas_en_blockchain,
    count(*) FILTER (WHERE (controlado = true)) AS controladas,
    count(*) FILTER (WHERE (estado = 'DISPENSADA'::public.estado_receta_enum)) AS dispensadas
   FROM public.receta
  GROUP BY (date_trunc('month'::text, fecha_emision))
  ORDER BY ((date_trunc('month'::text, fecha_emision))::date) DESC;


ALTER VIEW public.vw_recetas_blockchain OWNER TO postgres;

--
-- Name: vw_top_medicamentos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_top_medicamentos AS
 SELECT m.id AS medicamento_id,
    m.nombre AS medicamento,
    sum(df.cantidad) AS unidades_vendidas,
    sum(df.subtotal) AS monto_total,
    count(DISTINCT df.factura_id) AS num_facturas
   FROM ((public.detalle_factura df
     JOIN public.medicamento m ON ((m.id = df.medicamento_id)))
     JOIN public.factura f ON (((f.id = df.factura_id) AND (f.estado = 'PAGADA'::public.estado_factura_enum))))
  GROUP BY m.id, m.nombre
  ORDER BY (sum(df.cantidad)) DESC;


ALTER VIEW public.vw_top_medicamentos OWNER TO postgres;

--
-- Name: vw_ventas_diarias; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_ventas_diarias AS
 SELECT date(fecha) AS dia,
    count(*) AS num_facturas,
    COALESCE(sum(total), (0)::numeric) AS total_vendido,
    (COALESCE(avg(total), (0)::numeric))::numeric(12,2) AS ticket_promedio
   FROM public.factura
  WHERE (estado = 'PAGADA'::public.estado_factura_enum)
  GROUP BY (date(fecha))
  ORDER BY (date(fecha)) DESC;


ALTER VIEW public.vw_ventas_diarias OWNER TO postgres;

--
-- Name: categoria id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria ALTER COLUMN id SET DEFAULT nextval('public.categoria_id_seq'::regclass);


--
-- Name: rol id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol ALTER COLUMN id SET DEFAULT nextval('public.rol_id_seq'::regclass);


--
-- Data for Name: categoria; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categoria (id, nombre, descripcion) FROM stdin;
1	Analgesicos	Para alivio del dolor
2	Antibioticos	Combate infecciones bacterianas
3	Antiinflamatorios	Reduce la inflamacion
4	Antihistaminicos	Para alergias
5	Antihipertensivos	Control de presion arterial
6	Cardiologicos	Salud cardiovascular
7	Controlados	Sustancias controladas (requieren receta inmutable)
8	Vitaminas	Suplementos vitaminicos y minerales
\.


--
-- Data for Name: detalle_factura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_factura (id, factura_id, medicamento_id, lote_id, receta_id, cantidad, precio_unitario, subtotal) FROM stdin;
\.


--
-- Data for Name: detalle_receta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.detalle_receta (id, receta_id, medicamento_id, cantidad, posologia) FROM stdin;
e7adf1b8-11df-4a2e-a760-13c8682cabfe	e470f38f-a2bf-4776-a34b-58e4193e7e7f	cccc6666-cccc-6666-cccc-666666666666	1	d
11e9ee5f-afaf-4477-bc87-e4c0e274c175	7bc7d7c5-640f-48ff-98d8-39214a2901f8	cccc7777-cccc-7777-cccc-777777777777	1	ff
\.


--
-- Data for Name: factura; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.factura (id, numero, paciente_id, usuario_id, fecha, subtotal, descuento, total, metodo_pago, estado, created_at, updated_at) FROM stdin;
ffff0001-ffff-0001-ffff-000000000001	F-2026-000010	\N	33333333-3333-3333-3333-333333333333	2026-04-28 16:44:12.097686-04	10.00	0.00	10.00	EFECTIVO	PAGADA	2026-04-28 16:44:12.097686-04	2026-04-28 16:44:12.097686-04
ffff0003-ffff-0003-ffff-000000000003	F-2026-000012	\N	33333333-3333-3333-3333-333333333333	2026-05-02 16:44:12.097686-04	17.00	0.00	17.00	TARJETA	PAGADA	2026-05-02 16:44:12.097686-04	2026-05-02 16:44:12.097686-04
ffff0004-ffff-0004-ffff-000000000004	F-2026-000013	aaaa1111-aaaa-1111-aaaa-111111111111	33333333-3333-3333-3333-333333333333	2026-05-03 16:44:12.097686-04	225.00	10.00	215.00	TARJETA	PAGADA	2026-05-03 16:44:12.097686-04	2026-05-03 16:44:12.097686-04
ffff0005-ffff-0005-ffff-000000000005	F-2026-000014	\N	33333333-3333-3333-3333-333333333333	2026-05-05 16:44:12.097686-04	39.00	0.00	39.00	EFECTIVO	PAGADA	2026-05-05 16:44:12.097686-04	2026-05-05 16:44:12.097686-04
ffff0006-ffff-0006-ffff-000000000006	F-2026-000015	aaaa2222-aaaa-2222-aaaa-222222222222	33333333-3333-3333-3333-333333333333	2026-05-06 16:44:12.097686-04	75.00	0.00	75.00	TRANSFERENCIA	PAGADA	2026-05-06 16:44:12.097686-04	2026-05-06 16:44:12.097686-04
ffff0007-ffff-0007-ffff-000000000007	F-2026-000016	aaaa2222-aaaa-2222-aaaa-222222222222	33333333-3333-3333-3333-333333333333	2026-05-08 16:44:12.097686-04	75.00	0.00	75.00	EFECTIVO	PAGADA	2026-05-08 16:44:12.097686-04	2026-05-08 16:44:12.097686-04
ffff0009-ffff-0009-ffff-000000000009	F-2026-000018	aaaa1111-aaaa-1111-aaaa-111111111111	33333333-3333-3333-3333-333333333333	2026-05-10 16:44:12.097686-04	72.00	0.00	72.00	TRANSFERENCIA	PAGADA	2026-05-10 16:44:12.097686-04	2026-05-10 16:44:12.097686-04
ffff0010-ffff-0010-ffff-000000000010	F-2026-000019	\N	33333333-3333-3333-3333-333333333333	2026-05-11 16:44:12.097686-04	15.00	0.00	15.00	EFECTIVO	PAGADA	2026-05-11 16:44:12.097686-04	2026-05-11 16:44:12.097686-04
ffff0011-ffff-0011-ffff-000000000011	F-2026-000020	aaaa3333-aaaa-3333-aaaa-333333333333	33333333-3333-3333-3333-333333333333	2026-05-13 16:44:12.097686-04	75.00	0.00	75.00	EFECTIVO	PAGADA	2026-05-13 16:44:12.097686-04	2026-05-13 16:44:12.097686-04
ffff0012-ffff-0012-ffff-000000000012	F-2026-000021	aaaa5555-aaaa-5555-aaaa-555555555555	33333333-3333-3333-3333-333333333333	2026-05-14 16:44:12.097686-04	32.50	0.00	32.50	TARJETA	PAGADA	2026-05-14 16:44:12.097686-04	2026-05-14 16:44:12.097686-04
ffff0013-ffff-0013-ffff-000000000013	F-2026-000022	\N	11111111-1111-1111-1111-111111111111	2026-05-15 16:44:12.097686-04	19.50	0.00	19.50	EFECTIVO	PAGADA	2026-05-15 16:44:12.097686-04	2026-05-15 16:44:12.097686-04
ffff0014-ffff-0014-ffff-000000000014	F-2026-000023	aaaa4444-aaaa-4444-aaaa-444444444444	33333333-3333-3333-3333-333333333333	2026-05-16 16:44:12.097686-04	72.00	0.00	72.00	TARJETA	PAGADA	2026-05-16 16:44:12.097686-04	2026-05-16 16:44:12.097686-04
ffff0015-ffff-0015-ffff-000000000015	F-2026-000024	\N	33333333-3333-3333-3333-333333333333	2026-05-17 16:44:12.097686-04	44.00	0.00	44.00	EFECTIVO	PAGADA	2026-05-17 16:44:12.097686-04	2026-05-17 16:44:12.097686-04
ffff0016-ffff-0016-ffff-000000000016	F-2026-000025	aaaa3333-aaaa-3333-aaaa-333333333333	33333333-3333-3333-3333-333333333333	2026-05-18 16:44:12.097686-04	180.00	0.00	180.00	TARJETA	PAGADA	2026-05-18 16:44:12.097686-04	2026-05-18 16:44:12.097686-04
ffff0017-ffff-0017-ffff-000000000017	F-2026-000026	\N	33333333-3333-3333-3333-333333333333	2026-05-19 16:44:12.097686-04	13.00	0.00	13.00	QR	PAGADA	2026-05-19 16:44:12.097686-04	2026-05-19 16:44:12.097686-04
ffff0018-ffff-0018-ffff-000000000018	F-2026-000027	aaaa5555-aaaa-5555-aaaa-555555555555	33333333-3333-3333-3333-333333333333	2026-05-20 16:44:12.097686-04	75.00	0.00	75.00	EFECTIVO	PAGADA	2026-05-20 16:44:12.097686-04	2026-05-20 16:44:12.097686-04
ffff0020-ffff-0020-ffff-000000000020	F-2026-000029	\N	33333333-3333-3333-3333-333333333333	2026-05-22 16:44:12.097686-04	13.00	0.00	13.00	EFECTIVO	PAGADA	2026-05-22 16:44:12.097686-04	2026-05-22 16:44:12.097686-04
ffff0021-ffff-0021-ffff-000000000021	F-2026-000030	aaaa6666-aaaa-6666-aaaa-666666666666	33333333-3333-3333-3333-333333333333	2026-05-23 16:44:12.097686-04	72.00	0.00	72.00	TRANSFERENCIA	PAGADA	2026-05-23 16:44:12.097686-04	2026-05-23 16:44:12.097686-04
ffff0022-ffff-0022-ffff-000000000022	F-2026-000031	aaaa7777-aaaa-7777-aaaa-777777777777	33333333-3333-3333-3333-333333333333	2026-05-24 16:44:12.097686-04	30.00	0.00	30.00	QR	PAGADA	2026-05-24 16:44:12.097686-04	2026-05-24 16:44:12.097686-04
ffff0023-ffff-0023-ffff-000000000023	F-2026-000032	\N	33333333-3333-3333-3333-333333333333	2026-05-25 16:44:12.097686-04	23.50	0.00	23.50	EFECTIVO	PAGADA	2026-05-25 16:44:12.097686-04	2026-05-25 16:44:12.097686-04
ffff0024-ffff-0024-ffff-000000000024	F-2026-000033	aaaa8888-aaaa-8888-aaaa-888888888888	33333333-3333-3333-3333-333333333333	2026-05-26 16:44:12.097686-04	58.00	5.00	53.00	TARJETA	PAGADA	2026-05-26 16:44:12.097686-04	2026-05-26 16:44:12.097686-04
ffff0025-ffff-0025-ffff-000000000025	F-2026-000034	aaaa1111-aaaa-1111-aaaa-111111111111	33333333-3333-3333-3333-333333333333	2026-05-27 16:44:12.097686-04	45.00	0.00	45.00	EFECTIVO	PAGADA	2026-05-27 16:44:12.097686-04	2026-05-27 16:44:12.097686-04
ffff0027-ffff-0027-ffff-000000000027	F-2026-000036	\N	33333333-3333-3333-3333-333333333333	2026-05-28 14:44:12.097686-04	10.00	0.00	10.00	EFECTIVO	ANULADA	2026-05-28 14:44:12.097686-04	2026-05-28 15:44:12.097686-04
ffff0028-ffff-0028-ffff-000000000028	F-2026-000037	\N	33333333-3333-3333-3333-333333333333	2026-05-27 16:44:12.097686-04	8.50	0.00	8.50	EFECTIVO	ANULADA	2026-05-27 16:44:12.097686-04	2026-05-27 20:44:12.097686-04
ffff0029-ffff-0029-ffff-000000000029	F-2026-000038	aaaa6666-aaaa-6666-aaaa-666666666666	33333333-3333-3333-3333-333333333333	2026-05-23 16:44:12.097686-04	25.00	0.00	25.00	TARJETA	ANULADA	2026-05-23 16:44:12.097686-04	2026-05-24 16:44:12.097686-04
ffff0030-ffff-0030-ffff-000000000030	F-2026-000039	aaaa4444-aaaa-4444-aaaa-444444444444	11111111-1111-1111-1111-111111111111	2026-05-27 16:44:12.097686-04	65.00	0.00	65.00	EFECTIVO	PENDIENTE	2026-05-27 16:44:12.097686-04	2026-05-27 16:44:12.097686-04
ffff0002-ffff-0002-ffff-000000000002	F-2026-000011	aaaa4444-aaaa-4444-aaaa-444444444444	33333333-3333-3333-3333-333333333333	2026-04-30 16:44:12.097686-04	21.50	0.00	21.50	EFECTIVO	PAGADA	2026-04-30 16:44:12.097686-04	2026-06-01 17:46:59.674542-04
ffff0008-ffff-0008-ffff-000000000008	F-2026-000017	\N	33333333-3333-3333-3333-333333333333	2026-05-09 16:44:12.097686-04	27.00	0.00	27.00	QR	PAGADA	2026-05-09 16:44:12.097686-04	2026-06-01 17:46:59.674542-04
ffff0019-ffff-0019-ffff-000000000019	F-2026-000028	\N	33333333-3333-3333-3333-333333333333	2026-05-21 16:44:12.097686-04	26.50	0.00	26.50	EFECTIVO	PAGADA	2026-05-21 16:44:12.097686-04	2026-06-01 17:46:59.674542-04
ffff0026-ffff-0026-ffff-000000000026	F-2026-000035	\N	33333333-3333-3333-3333-333333333333	2026-05-28 12:44:12.097686-04	19.50	0.00	19.50	EFECTIVO	PAGADA	2026-05-28 12:44:12.097686-04	2026-06-01 17:46:59.674542-04
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	1	schema	SQL	V1__schema.sql	589502202	postgres	2026-05-28 07:12:36.421294	653	t
2	2	views bi	SQL	V2__views_bi.sql	1367387292	postgres	2026-05-28 07:12:37.252429	40	t
3	3	seed roles	SQL	V3__seed_roles.sql	25175936	postgres	2026-05-28 07:12:37.348086	24	t
4	4	seed demo	SQL	V4__seed_demo.sql	-1488316194	postgres	2026-05-28 07:12:37.398438	62	t
5	5	seed transacciones	SQL	V5__seed_transacciones.sql	-1117342233	postgres	2026-06-01 17:46:59.524913	179	t
\.


--
-- Data for Name: lote; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lote (id, medicamento_id, proveedor_id, codigo_lote, fecha_vencimiento, cantidad_inicial, cantidad_actual, precio_compra, created_at, updated_at) FROM stdin;
dddd1111-dddd-1111-dddd-111111111111	cccc1111-cccc-1111-cccc-111111111111	bbbb1111-bbbb-1111-bbbb-111111111111	PAR-2027-001	2027-06-30	200	163	3.00	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd2222-dddd-2222-dddd-222222222222	cccc2222-cccc-2222-cccc-222222222222	bbbb1111-bbbb-1111-bbbb-111111111111	IBU-2027-002	2027-08-15	150	144	5.00	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd3333-dddd-3333-dddd-333333333333	cccc3333-cccc-3333-cccc-333333333333	bbbb2222-bbbb-2222-bbbb-222222222222	AMX-2026-003	2026-12-31	80	65	9.00	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd4444-dddd-4444-dddd-444444444444	cccc4444-cccc-4444-cccc-444444444444	bbbb1111-bbbb-1111-bbbb-111111111111	LOR-2027-004	2027-04-20	100	93	4.00	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd5555-dddd-5555-dddd-555555555555	cccc5555-cccc-5555-cccc-555555555555	bbbb2222-bbbb-2222-bbbb-222222222222	ENA-2026-005	2026-10-15	60	42	7.50	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd6666-dddd-6666-dddd-666666666666	cccc6666-cccc-6666-cccc-666666666666	bbbb2222-bbbb-2222-bbbb-222222222222	MOR-2026-006	2026-08-30	20	11	30.00	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd7777-dddd-7777-dddd-777777777777	cccc7777-cccc-7777-cccc-777777777777	bbbb2222-bbbb-2222-bbbb-222222222222	DIA-2026-007	2026-11-10	25	22	16.00	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
dddd8888-dddd-8888-dddd-888888888888	cccc8888-cccc-8888-cccc-888888888888	bbbb1111-bbbb-1111-bbbb-111111111111	VTC-2027-008	2027-09-05	300	274	4.50	2026-05-28 07:12:37.42413-04	2026-06-01 17:46:59.674542-04
\.


--
-- Data for Name: medicamento; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.medicamento (id, nombre, descripcion, categoria_id, precio_venta, requiere_receta, controlado, stock_minimo, activo, created_at, updated_at) FROM stdin;
cccc1111-cccc-1111-cccc-111111111111	Paracetamol 500mg	Tabletas analgesico-antipiretico	1	5.00	f	f	50	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc2222-cccc-2222-cccc-222222222222	Ibuprofeno 400mg	Antiinflamatorio no esteroideo	3	8.50	f	f	40	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc3333-cccc-3333-cccc-333333333333	Amoxicilina 500mg	Antibiotico de amplio espectro	2	15.00	t	f	30	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc4444-cccc-4444-cccc-444444444444	Loratadina 10mg	Antihistaminico de segunda generacion	4	7.00	f	f	30	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc5555-cccc-5555-cccc-555555555555	Enalapril 10mg	Antihipertensivo IECA	5	12.00	t	f	25	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc6666-cccc-6666-cccc-666666666666	Morfina 10mg	Opioide controlado	7	45.00	t	t	10	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc7777-cccc-7777-cccc-777777777777	Diazepam 5mg	Benzodiacepina controlada	7	25.00	t	t	15	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
cccc8888-cccc-8888-cccc-888888888888	Vitamina C 1g	Suplemento vitaminico	8	6.50	f	f	100	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
579fe1c1-fe4f-47a9-a01d-eccef6a6679c	Tecnologia		2	0.00	f	f	0	t	2026-06-01 18:57:25.156761-04	2026-06-01 18:57:25.156761-04
6ddd1104-fe56-43ab-b819-7e07cac99a83	9		2	0.00	f	f	0	t	2026-06-01 18:58:19.355016-04	2026-06-01 18:58:19.355016-04
b97e2c4f-4b63-438c-84ae-375c938c32fd	Gato		\N	20.00	t	t	20	t	2026-06-01 19:02:28.707433-04	2026-06-01 19:02:28.707433-04
\.


--
-- Data for Name: movimiento_inventario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movimiento_inventario (id, lote_id, tipo, cantidad, motivo, usuario_id, fecha) FROM stdin;
acfcaf5c-b46c-4f9a-923a-42023e722aac	dddd1111-dddd-1111-dddd-111111111111	ENTRADA	200	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
20327840-cd9f-4df6-ac16-dac5a218ae9c	dddd2222-dddd-2222-dddd-222222222222	ENTRADA	150	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
da447bbb-1783-4655-a48c-637f516d8054	dddd3333-dddd-3333-dddd-333333333333	ENTRADA	80	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
7452fb08-cc34-4222-8ce7-58eaf74f4fd1	dddd4444-dddd-4444-dddd-444444444444	ENTRADA	100	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
b6dbb7a2-ec2d-4458-b729-dce3939fcbe2	dddd5555-dddd-5555-dddd-555555555555	ENTRADA	60	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
75fe5659-38ac-42ba-9aba-b5b8c314663b	dddd6666-dddd-6666-dddd-666666666666	ENTRADA	20	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
ac2e5fc9-cd9c-442e-a916-fd7e30c95625	dddd7777-dddd-7777-dddd-777777777777	ENTRADA	25	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
63058b7e-42f1-41aa-b09a-d534ba2a9229	dddd8888-dddd-8888-dddd-888888888888	ENTRADA	300	Carga inicial de seed	33333333-3333-3333-3333-333333333333	2026-05-28 07:12:37.42413-04
bbbb0000-bbbb-0000-bbbb-000000000001	dddd1111-dddd-1111-dddd-111111111111	SALIDA	2	Venta F-2026-000010	33333333-3333-3333-3333-333333333333	2026-04-28 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000002	dddd1111-dddd-1111-dddd-111111111111	SALIDA	3	Venta F-2026-000011	33333333-3333-3333-3333-333333333333	2026-04-30 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000003	dddd8888-dddd-8888-dddd-888888888888	SALIDA	1	Venta F-2026-000011	33333333-3333-3333-3333-333333333333	2026-04-30 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000004	dddd2222-dddd-2222-dddd-222222222222	SALIDA	2	Venta F-2026-000012	33333333-3333-3333-3333-333333333333	2026-05-02 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000005	dddd6666-dddd-6666-dddd-666666666666	SALIDA	5	Venta F-2026-000013	33333333-3333-3333-3333-333333333333	2026-05-03 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000006	dddd8888-dddd-8888-dddd-888888888888	SALIDA	6	Venta F-2026-000014	33333333-3333-3333-3333-333333333333	2026-05-05 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000007	dddd7777-dddd-7777-dddd-777777777777	SALIDA	3	Venta F-2026-000015	33333333-3333-3333-3333-333333333333	2026-05-06 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000008	dddd3333-dddd-3333-dddd-333333333333	SALIDA	5	Venta F-2026-000016	33333333-3333-3333-3333-333333333333	2026-05-08 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000009	dddd4444-dddd-4444-dddd-444444444444	SALIDA	2	Venta F-2026-000017	33333333-3333-3333-3333-333333333333	2026-05-09 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000010	dddd8888-dddd-8888-dddd-888888888888	SALIDA	2	Venta F-2026-000017	33333333-3333-3333-3333-333333333333	2026-05-09 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000011	dddd5555-dddd-5555-dddd-555555555555	SALIDA	6	Venta F-2026-000018	33333333-3333-3333-3333-333333333333	2026-05-10 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000012	dddd1111-dddd-1111-dddd-111111111111	SALIDA	3	Venta F-2026-000019	33333333-3333-3333-3333-333333333333	2026-05-11 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000013	dddd3333-dddd-3333-dddd-333333333333	SALIDA	5	Venta F-2026-000020	33333333-3333-3333-3333-333333333333	2026-05-13 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000014	dddd8888-dddd-8888-dddd-888888888888	SALIDA	5	Venta F-2026-000021	33333333-3333-3333-3333-333333333333	2026-05-14 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000015	dddd8888-dddd-8888-dddd-888888888888	SALIDA	3	Venta F-2026-000022	11111111-1111-1111-1111-111111111111	2026-05-15 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000016	dddd5555-dddd-5555-dddd-555555555555	SALIDA	6	Venta F-2026-000023	33333333-3333-3333-3333-333333333333	2026-05-16 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000017	dddd2222-dddd-2222-dddd-222222222222	SALIDA	4	Venta F-2026-000024	33333333-3333-3333-3333-333333333333	2026-05-17 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000018	dddd1111-dddd-1111-dddd-111111111111	SALIDA	2	Venta F-2026-000024	33333333-3333-3333-3333-333333333333	2026-05-17 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000019	dddd6666-dddd-6666-dddd-666666666666	SALIDA	4	Venta F-2026-000025	33333333-3333-3333-3333-333333333333	2026-05-18 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000020	dddd8888-dddd-8888-dddd-888888888888	SALIDA	2	Venta F-2026-000026	33333333-3333-3333-3333-333333333333	2026-05-19 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000021	dddd3333-dddd-3333-dddd-333333333333	SALIDA	5	Venta F-2026-000027	33333333-3333-3333-3333-333333333333	2026-05-20 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000022	dddd1111-dddd-1111-dddd-111111111111	SALIDA	4	Venta F-2026-000028	33333333-3333-3333-3333-333333333333	2026-05-21 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000023	dddd8888-dddd-8888-dddd-888888888888	SALIDA	1	Venta F-2026-000028	33333333-3333-3333-3333-333333333333	2026-05-21 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000024	dddd8888-dddd-8888-dddd-888888888888	SALIDA	2	Venta F-2026-000029	33333333-3333-3333-3333-333333333333	2026-05-22 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000025	dddd5555-dddd-5555-dddd-555555555555	SALIDA	6	Venta F-2026-000030	33333333-3333-3333-3333-333333333333	2026-05-23 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000026	dddd1111-dddd-1111-dddd-111111111111	SALIDA	6	Venta F-2026-000031	33333333-3333-3333-3333-333333333333	2026-05-24 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000027	dddd8888-dddd-8888-dddd-888888888888	SALIDA	1	Venta F-2026-000032	33333333-3333-3333-3333-333333333333	2026-05-25 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000028	dddd4444-dddd-4444-dddd-444444444444	SALIDA	1	Venta F-2026-000032	33333333-3333-3333-3333-333333333333	2026-05-25 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000029	dddd1111-dddd-1111-dddd-111111111111	SALIDA	2	Venta F-2026-000032	33333333-3333-3333-3333-333333333333	2026-05-25 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000030	dddd4444-dddd-4444-dddd-444444444444	SALIDA	4	Venta F-2026-000033	33333333-3333-3333-3333-333333333333	2026-05-26 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000031	dddd1111-dddd-1111-dddd-111111111111	SALIDA	6	Venta F-2026-000033	33333333-3333-3333-3333-333333333333	2026-05-26 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000032	dddd1111-dddd-1111-dddd-111111111111	SALIDA	9	Venta F-2026-000034	33333333-3333-3333-3333-333333333333	2026-05-27 16:44:12.097686-04
bbbb0000-bbbb-0000-bbbb-000000000033	dddd8888-dddd-8888-dddd-888888888888	SALIDA	3	Venta F-2026-000035	33333333-3333-3333-3333-333333333333	2026-05-28 12:44:12.097686-04
\.


--
-- Data for Name: paciente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.paciente (id, supabase_uid, ci, nombre, apellido, telefono, email, fecha_nacimiento, created_at, updated_at) FROM stdin;
aaaa2222-aaaa-2222-aaaa-222222222222	\N	7654321	Ana	Mamani	70022334	\N	1990-09-23	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
aaaa3333-aaaa-3333-aaaa-333333333333	\N	9876543	Pedro	Choque	70033445	\N	1978-01-07	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
aaaa1111-aaaa-1111-aaaa-111111111111	7af9fa2a-bf32-4b25-9c54-7bfd89330bfe	1234567	Carlos	Rodriguez	70011223	paciente@clinica.com	1985-04-12	2026-05-28 07:12:37.42413-04	2026-05-28 08:35:00.096649-04
aaaa4444-aaaa-4444-aaaa-444444444444	\N	1122334	Maria	Lopez	70044556	maria.lopez@example.com	1985-03-15	2026-04-18 16:44:12.097686-04	2026-04-18 16:44:12.097686-04
aaaa5555-aaaa-5555-aaaa-555555555555	\N	2233445	Jose	Vargas	70055667	jose.vargas@example.com	1978-07-20	2026-04-20 16:44:12.097686-04	2026-04-20 16:44:12.097686-04
aaaa6666-aaaa-6666-aaaa-666666666666	\N	3344556	Lucia	Mamani	70066778	lucia.mamani@example.com	1992-11-08	2026-04-23 16:44:12.097686-04	2026-04-23 16:44:12.097686-04
aaaa7777-aaaa-7777-aaaa-777777777777	\N	4455667	Roberto	Quispe	70077889	roberto.quispe@example.com	1980-05-30	2026-04-25 16:44:12.097686-04	2026-04-25 16:44:12.097686-04
aaaa8888-aaaa-8888-aaaa-888888888888	\N	5566778	Sandra	Flores	70088990	sandra.flores@example.com	1995-09-22	2026-04-28 16:44:12.097686-04	2026-04-28 16:44:12.097686-04
3f49481e-8d4a-44ea-b434-ed653e225cfa	\N	21233	afafa	fafaf	5543434	caaga@gmail.com	2026-06-01	2026-06-01 19:25:36.307331-04	2026-06-01 19:25:36.307331-04
\.


--
-- Data for Name: proveedor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.proveedor (id, nombre, nit, telefono, email, direccion, activo, created_at, updated_at) FROM stdin;
bbbb1111-bbbb-1111-bbbb-111111111111	FarmaSur SRL	1023456789	22440011	ventas@farmasur.bo	Av. Salud 123, Santa Cruz	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
bbbb2222-bbbb-2222-bbbb-222222222222	Distribuidora MD	1098765432	22550022	pedidos@mdistribu.bo	Calle Comercio 456, La Paz	t	2026-05-28 07:12:37.42413-04	2026-05-28 07:12:37.42413-04
\.


--
-- Data for Name: receta; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.receta (id, paciente_id, medico_nombre, medico_uid, diagnostico, fecha_emision, controlado, hash_documento, blockchain_tx, blockchain_id, estado, created_at, updated_at) FROM stdin;
e470f38f-a2bf-4776-a34b-58e4193e7e7f	aaaa3333-aaaa-3333-aaaa-333333333333	Dr. Juan Perez	611a93f6-eb88-46b4-89fc-595a7746ec41	f	2026-06-01 23:53:29.423192-04	t	0cdd3600e3064014b7cbe109cf83aa220bb28696d58bfa6d0c591a4bd45c52e8	0x2c9399e5f7d8ee64e56adb207af429dbf1604197332f1ba84b56e8c2457c6bf6	0	EMITIDA	2026-06-01 23:53:29.52167-04	2026-06-01 23:53:29.415884-04
7bc7d7c5-640f-48ff-98d8-39214a2901f8	aaaa3333-aaaa-3333-aaaa-333333333333	Dr. Juan Perez	611a93f6-eb88-46b4-89fc-595a7746ec41	ss	2026-06-01 23:54:17.276417-04	t	bdad233cf8d0c7fbde1539d7ab458dba217f44d30c67878e873ad497a3605b68	0xea6218baff667cd0ab27ca34da2eaf7d50a82cd295ff29b73c25181bc2ba70bb	1	EMITIDA	2026-06-01 23:54:17.281435-04	2026-06-01 23:54:17.274034-04
\.


--
-- Data for Name: rol; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rol (id, nombre, descripcion) FROM stdin;
1	ADMINISTRADOR	Acceso total al sistema, gestion de usuarios y BI
2	MEDICO	Emite recetas, dispara blockchain, ve historia clinica
3	FARMACEUTICO	Caja, inventario, dispensacion, verificar recetas
4	PACIENTE	Consulta sus facturas y recetas
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuario (id, supabase_uid, nombre, email, rol_id, activo, created_at, updated_at) FROM stdin;
11111111-1111-1111-1111-111111111111	58289c11-b4b9-4e90-bf9a-05a5bd61508e	Admin Demo	admin@clinica.com	1	t	2026-05-28 07:12:37.42413-04	2026-05-28 08:11:55.262239-04
44444444-4444-4444-4444-444444444444	7af9fa2a-bf32-4b25-9c54-7bfd89330bfe	Carlos Rodriguez	paciente@clinica.com	4	t	2026-05-28 07:12:37.42413-04	2026-05-28 08:35:00.096649-04
22222222-2222-2222-2222-222222222222	611a93f6-eb88-46b4-89fc-595a7746ec41	Dr. Juan Perez	medico@clinica.com	2	t	2026-05-28 07:12:37.42413-04	2026-05-28 08:55:18.298366-04
33333333-3333-3333-3333-333333333333	667e895a-9b69-4c72-836c-0b480c92fce8	Maria Gonzalez	farma@clinica.com	3	t	2026-05-28 07:12:37.42413-04	2026-05-28 08:55:18.298366-04
\.


--
-- Name: categoria_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categoria_id_seq', 8, true);


--
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rol_id_seq', 4, true);


--
-- Name: categoria categoria_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_nombre_key UNIQUE (nombre);


--
-- Name: categoria categoria_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id);


--
-- Name: detalle_factura detalle_factura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT detalle_factura_pkey PRIMARY KEY (id);


--
-- Name: detalle_receta detalle_receta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT detalle_receta_pkey PRIMARY KEY (id);


--
-- Name: detalle_receta detalle_receta_receta_id_medicamento_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT detalle_receta_receta_id_medicamento_id_key UNIQUE (receta_id, medicamento_id);


--
-- Name: factura factura_numero_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_numero_key UNIQUE (numero);


--
-- Name: factura factura_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: lote lote_medicamento_id_codigo_lote_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lote
    ADD CONSTRAINT lote_medicamento_id_codigo_lote_key UNIQUE (medicamento_id, codigo_lote);


--
-- Name: lote lote_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lote
    ADD CONSTRAINT lote_pkey PRIMARY KEY (id);


--
-- Name: medicamento medicamento_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamento
    ADD CONSTRAINT medicamento_pkey PRIMARY KEY (id);


--
-- Name: movimiento_inventario movimiento_inventario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT movimiento_inventario_pkey PRIMARY KEY (id);


--
-- Name: paciente paciente_ci_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_ci_key UNIQUE (ci);


--
-- Name: paciente paciente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_pkey PRIMARY KEY (id);


--
-- Name: paciente paciente_supabase_uid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.paciente
    ADD CONSTRAINT paciente_supabase_uid_key UNIQUE (supabase_uid);


--
-- Name: proveedor proveedor_nit_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_nit_key UNIQUE (nit);


--
-- Name: proveedor proveedor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.proveedor
    ADD CONSTRAINT proveedor_pkey PRIMARY KEY (id);


--
-- Name: receta receta_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receta
    ADD CONSTRAINT receta_pkey PRIMARY KEY (id);


--
-- Name: rol rol_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_nombre_key UNIQUE (nombre);


--
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_email_key UNIQUE (email);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_supabase_uid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_supabase_uid_key UNIQUE (supabase_uid);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_detalle_factura_factura; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_detalle_factura_factura ON public.detalle_factura USING btree (factura_id);


--
-- Name: idx_detalle_factura_medicamento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_detalle_factura_medicamento ON public.detalle_factura USING btree (medicamento_id);


--
-- Name: idx_detalle_receta_receta; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_detalle_receta_receta ON public.detalle_receta USING btree (receta_id);


--
-- Name: idx_factura_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_fecha ON public.factura USING btree (fecha);


--
-- Name: idx_factura_paciente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_paciente ON public.factura USING btree (paciente_id);


--
-- Name: idx_factura_usuario; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_factura_usuario ON public.factura USING btree (usuario_id);


--
-- Name: idx_lote_medicamento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lote_medicamento ON public.lote USING btree (medicamento_id);


--
-- Name: idx_lote_vencimiento; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_lote_vencimiento ON public.lote USING btree (fecha_vencimiento);


--
-- Name: idx_medicamento_categoria; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_medicamento_categoria ON public.medicamento USING btree (categoria_id);


--
-- Name: idx_medicamento_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_medicamento_nombre ON public.medicamento USING btree (nombre);


--
-- Name: idx_movimiento_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_movimiento_fecha ON public.movimiento_inventario USING btree (fecha);


--
-- Name: idx_movimiento_lote; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_movimiento_lote ON public.movimiento_inventario USING btree (lote_id);


--
-- Name: idx_paciente_ci; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_paciente_ci ON public.paciente USING btree (ci);


--
-- Name: idx_paciente_supabase_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_paciente_supabase_uid ON public.paciente USING btree (supabase_uid);


--
-- Name: idx_receta_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_receta_fecha ON public.receta USING btree (fecha_emision);


--
-- Name: idx_receta_medico_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_receta_medico_uid ON public.receta USING btree (medico_uid);


--
-- Name: idx_receta_paciente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_receta_paciente ON public.receta USING btree (paciente_id);


--
-- Name: idx_receta_tx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_receta_tx ON public.receta USING btree (blockchain_tx);


--
-- Name: idx_usuario_rol; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuario_rol ON public.usuario USING btree (rol_id);


--
-- Name: idx_usuario_supabase_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_usuario_supabase_uid ON public.usuario USING btree (supabase_uid);


--
-- Name: factura trg_factura_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_factura_updated_at BEFORE UPDATE ON public.factura FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: lote trg_lote_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_lote_updated_at BEFORE UPDATE ON public.lote FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: medicamento trg_medicamento_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_medicamento_updated_at BEFORE UPDATE ON public.medicamento FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: paciente trg_paciente_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_paciente_updated_at BEFORE UPDATE ON public.paciente FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: proveedor trg_proveedor_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_proveedor_updated_at BEFORE UPDATE ON public.proveedor FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: receta trg_receta_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_receta_updated_at BEFORE UPDATE ON public.receta FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: usuario trg_usuario_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_usuario_updated_at BEFORE UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: detalle_factura detalle_factura_factura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT detalle_factura_factura_id_fkey FOREIGN KEY (factura_id) REFERENCES public.factura(id) ON DELETE CASCADE;


--
-- Name: detalle_factura detalle_factura_lote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT detalle_factura_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES public.lote(id);


--
-- Name: detalle_factura detalle_factura_medicamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT detalle_factura_medicamento_id_fkey FOREIGN KEY (medicamento_id) REFERENCES public.medicamento(id);


--
-- Name: detalle_factura detalle_factura_receta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_factura
    ADD CONSTRAINT detalle_factura_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES public.receta(id);


--
-- Name: detalle_receta detalle_receta_medicamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT detalle_receta_medicamento_id_fkey FOREIGN KEY (medicamento_id) REFERENCES public.medicamento(id);


--
-- Name: detalle_receta detalle_receta_receta_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.detalle_receta
    ADD CONSTRAINT detalle_receta_receta_id_fkey FOREIGN KEY (receta_id) REFERENCES public.receta(id) ON DELETE CASCADE;


--
-- Name: factura factura_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- Name: factura factura_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.factura
    ADD CONSTRAINT factura_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: lote lote_medicamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lote
    ADD CONSTRAINT lote_medicamento_id_fkey FOREIGN KEY (medicamento_id) REFERENCES public.medicamento(id);


--
-- Name: lote lote_proveedor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lote
    ADD CONSTRAINT lote_proveedor_id_fkey FOREIGN KEY (proveedor_id) REFERENCES public.proveedor(id);


--
-- Name: medicamento medicamento_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.medicamento
    ADD CONSTRAINT medicamento_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categoria(id);


--
-- Name: movimiento_inventario movimiento_inventario_lote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT movimiento_inventario_lote_id_fkey FOREIGN KEY (lote_id) REFERENCES public.lote(id);


--
-- Name: movimiento_inventario movimiento_inventario_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimiento_inventario
    ADD CONSTRAINT movimiento_inventario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuario(id);


--
-- Name: receta receta_paciente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.receta
    ADD CONSTRAINT receta_paciente_id_fkey FOREIGN KEY (paciente_id) REFERENCES public.paciente(id);


--
-- Name: usuario usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.rol(id);


--
-- PostgreSQL database dump complete
--

\unrestrict pT8k8SBYejHLY6vMR9NBvorP2PrL788xhNYX1jrOUbiSYrMkxlj5Oc5IA3KIqWM

