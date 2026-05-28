package com.clinica.gestion.common.context;

import com.clinica.gestion.usuario.Usuario;

public final class UsuarioContext {

    private static final ThreadLocal<Usuario> CURRENT = new ThreadLocal<>();

    private UsuarioContext() {}

    public static void set(Usuario u) { CURRENT.set(u); }
    public static Usuario current()   { return CURRENT.get(); }
    public static void clear()        { CURRENT.remove(); }
}
