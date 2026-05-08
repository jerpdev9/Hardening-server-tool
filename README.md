# 🛡️ Hardening Server Tool

**Herramienta interactiva de endurecimiento para servidores Ubuntu y Debian.**
Guía al usuario paso a paso, explicando cada acción antes de ejecutarla. Disponible en **Español e Inglés**.

> **Interactive step-by-step VPS hardening tool for Ubuntu and Debian.**
> Explains every action before running it. Available in **Spanish and English**.

---

## ¿Qué es esto? / What is this?

Cuando creas un servidor VPS por primera vez, viene con una configuración básica que lo deja expuesto a ataques. Este script te guía para cerrarlo correctamente, paso a paso, sin necesidad de conocimientos avanzados.

> When you create a VPS for the first time, it comes with a basic configuration that leaves it exposed to attacks. This script guides you to secure it properly, step by step, no advanced knowledge required.

---

## Requisitos / Requirements

| | |
|---|---|
| Sistema operativo | Ubuntu 20.04+ o Debian 10+ |
| Acceso | Root o usuario con `sudo` |
| Conexión | Internet activa en el servidor |

---

## Cómo instalarlo / How to install

### Opción 1 — Descargar desde el servidor (recomendado)

Conéctate a tu VPS por SSH y ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/jerpdev9/Hardening-server-tool/main/harden.sh \
     -o harden.sh && sudo bash harden.sh
```

> **¿Por qué descargar primero y no usar `curl | bash` directo?**
> El script es interactivo: hace preguntas y espera tus respuestas.
> Si lo pipeas directamente, no puede leer lo que escribes.

---

### Opción 2 — Subir desde tu máquina local por SCP

Si ya tienes el archivo `harden.sh` en tu computadora:

```bash
# 1. Súbelo al servidor
scp harden.sh root@IP_DE_TU_SERVIDOR:~/

# 2. Conéctate al servidor
ssh root@IP_DE_TU_SERVIDOR

# 3. Ejecútalo
sudo bash harden.sh
```

---

### Opción 3 — Clonar el repositorio completo

```bash
git clone https://github.com/jerpdev9/Hardening-server-tool.git
cd Hardening-server-tool
sudo bash harden.sh
```

---

## Cómo funciona / How it works

Al ejecutar el script, ocurre lo siguiente:

### 1. Selección de idioma
Lo primero que aparece es un menú para elegir el idioma:
```
╔══════════════════════════════════════════════════════╗
║             VPS HARDENER  v1.0                       ║
╠══════════════════════════════════════════════════════╣
║      Selecciona un idioma / Choose a language        ║
║          [1]  Español                                ║
║          [2]  English                                ║
╚══════════════════════════════════════════════════════╝
```

### 2. Verificaciones automáticas
El script verifica que:
- Se está ejecutando como administrador (root)
- El sistema operativo es Ubuntu o Debian

### 3. Pasos interactivos

Cada paso sigue este flujo:

```
─ PASO X de 7 — Nombre del paso ─────────────────────

  ¿Qué vamos a hacer?
  • Descripción clara de la acción
  • Explicación de por qué es importante

  ¿Deseas continuar? [s/n]: _
```

Si respondes **s** (sí / yes) → el paso se ejecuta.
Si respondes **n** (no) → el paso se salta y se continúa con el siguiente.

### 4. Resumen final
Al terminar, el script muestra qué pasos se completaron y cuáles se saltaron, junto con los próximos pasos recomendados.

---

## Llave SSH — Cómo obtenerla y enviarla / SSH Key — How to get it and send it

El script te pedirá tu llave pública SSH durante el paso 3. Aquí te explicamos cómo generarla y obtenerla.

> The script will ask for your SSH public key during step 3. Here's how to generate it and get it.

---

### 1. Generar la llave (si aún no tienes una) / Generate the key (if you don't have one yet)

Ejecuta esto en tu **máquina local** (no en el servidor):

```bash
ssh-keygen -t ed25519 -C "tu@email.com"
```

Acepta la ruta por defecto (`~/.ssh/id_ed25519`) y establece una contraseña opcional.

---

### 2. Ver tu llave pública / View your public key

```bash
cat ~/.ssh/id_ed25519.pub
```

El resultado se ve así:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... tu@email.com
```

Copia **todo** ese texto. El script te lo pedirá al configurar SSH.

> Si usas RSA en lugar de ed25519:
> ```bash
> cat ~/.ssh/id_rsa.pub
> ```

---

### 3. Enviar la llave al servidor (alternativa manual) / Send the key to the server (manual alternative)

Si prefieres configurar el acceso por llave **antes** de ejecutar el script, usa `ssh-copy-id`:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@IP_DE_TU_SERVIDOR
```

O manualmente, pegando la llave desde el servidor:

```bash
# Conéctate al servidor
ssh root@IP_DE_TU_SERVIDOR

# Crea el directorio y el archivo si no existen
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # pega aquí tu llave pública
chmod 600 ~/.ssh/authorized_keys
```

---

## Pasos incluidos / Included steps

| # | Español | English | Descripción |
|---|---------|---------|-------------|
| 1 | Actualizar el sistema | Update the system | `apt update && apt upgrade` |
| 2 | Crear usuario administrador | Create admin user | Nuevo usuario con sudo, sin usar root |
| 3 | Configurar SSH | Configure SSH | Cambiar puerto, agregar llave pública, deshabilitar contraseña |
| 4 | Firewall UFW | UFW Firewall | Bloquear todo excepto puertos necesarios |
| 5 | Fail2ban | Fail2ban | Bloquear IPs que fallan demasiados intentos |
| 6 | Actualizaciones automáticas | Automatic security updates | Parches de seguridad sin intervención manual |
| 7 | Zona horaria | Timezone | Logs con hora correcta |

> Cada paso es **completamente opcional**. Puedes saltarlo si ya lo tienes configurado o si no lo necesitas.

---

## Seguridad del propio script / Script safety

- **SSH**: Crea un respaldo de `/etc/ssh/sshd_config` antes de modificarlo. Si algo falla, lo restaura automáticamente.
- **Puerto SSH**: Muestra una advertencia clara con el nuevo comando de conexión antes de aplicar cambios.
- **Contraseña SSH**: Nunca la deshabilita sin confirmación explícita del usuario.
- **Firewall**: Abre el puerto SSH correcto automáticamente antes de activar UFW para evitar que te quedes sin acceso.

---

## Registro de acciones / Action log

Todas las acciones quedan registradas en:

```
/var/log/vps-hardener.log
```

---

## Autor / Author

Desarrollado por **jerp** — [github.com/jerpdev9](https://github.com/jerpdev9)

---

## Repositorio / Repository

```
https://github.com/jerpdev9/Hardening-server-tool
```
