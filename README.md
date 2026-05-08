# VPS Hardener

Herramienta interactiva de endurecimiento para servidores Ubuntu y Debian.
Guía al usuario paso a paso, explicando cada acción antes de ejecutarla.

> Interactive step-by-step VPS hardening tool for Ubuntu and Debian.
> Explains every action before running it — beginner friendly.

---

## Uso rápido / Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/USER/vps-hardener/main/harden.sh \
     -o harden.sh && sudo bash harden.sh
```

O si ya tienes el archivo / Or if you already have the file:

```bash
sudo bash harden.sh
```

**¿Por qué descargar primero en vez de `curl | bash`?**
El script es interactivo — hace preguntas. Si lo pipeas directamente, no puede leer tus respuestas.

---

## Pasos incluidos / Included steps

| # | ES | EN |
|---|----|----|
| 1 | Actualizar el sistema | Update the system |
| 2 | Crear usuario administrador | Create admin user |
| 3 | Configurar SSH (puerto + llaves) | Configure SSH (port + keys) |
| 4 | Firewall UFW | UFW Firewall |
| 5 | Fail2ban | Fail2ban |
| 6 | Actualizaciones automáticas | Automatic security updates |
| 7 | Zona horaria | Timezone |

Cada paso es **opcional** — puedes saltarlo si no lo necesitas.

---

## Requisitos / Requirements

- Ubuntu 20.04+ o Debian 10+
- Acceso root (`sudo`)
- Conexión a internet

---

## Subir al servidor por SCP / Upload via SCP

```bash
scp harden.sh root@IP_DEL_SERVIDOR:~/
ssh root@IP_DEL_SERVIDOR "bash harden.sh"
```

---

## Advertencias de seguridad / Security warnings

- **SSH**: El script hace respaldo de `/etc/ssh/sshd_config` antes de modificarlo.
  Si algo falla, restaura automáticamente la configuración original.
- **Puerto SSH**: Anota el nuevo puerto **antes** de cerrar tu sesión actual.
- **Contraseña SSH**: No deshabilites la autenticación por contraseña hasta verificar
  que tu llave SSH funciona correctamente.

---

## Log

El script guarda un registro de todas las acciones en:

```
/var/log/vps-hardener.log
```
