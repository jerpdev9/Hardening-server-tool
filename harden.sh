#!/bin/bash
# =============================================================================
#  VPS Hardener — Guía interactiva de seguridad / Interactive security guide
#  Plataformas / Platforms: Ubuntu / Debian
#
#  Uso / Usage:
#    curl -fsSL https://raw.githubusercontent.com/USER/vps-hardener/main/harden.sh \
#         -o harden.sh && sudo bash harden.sh
#    o / or:
#    sudo bash harden.sh
# =============================================================================

# ── ESTADO GLOBAL / GLOBAL STATE ──────────────────────────────────────────────
LANG_CODE=""
SSH_PORT="22"
NEW_USERNAME=""
STEPS_DONE=()
STEPS_SKIPPED=()
TOTAL_STEPS=7
LOG_FILE="/var/log/vps-hardener.log"

# ── COLORES / COLORS ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── LOG ────────────────────────────────────────────────────────────────────────
_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true; }

# ── HELPERS VISUALES / VISUAL HELPERS ─────────────────────────────────────────
info()    { echo -e "${CYAN}  ℹ  $1${NC}";   _log "INFO: $1"; }
success() { echo -e "${GREEN}  ✔  $1${NC}";  _log "OK: $1"; }
warning() { echo -e "${YELLOW}  ⚠  $1${NC}"; _log "WARN: $1"; }
error()   { echo -e "${RED}  ✘  $1${NC}";   _log "ERROR: $1"; }
blank()   { echo ""; }
line()    { echo -e "  ${DIM}──────────────────────────────────────────────────${NC}"; }

press_enter() {
    blank
    echo -e "  ${DIM}↩  $TXT_PRESS_ENTER${NC}"
    read -r _unused
}

# ── ENCABEZADO DE PASO / STEP HEADER ──────────────────────────────────────────
step_header() {
    local num=$1 title=$2
    clear
    blank
    echo -e "  ${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${BOLD}  $TXT_STEP_LABEL $num $TXT_STEP_OF $TOTAL_STEPS — $title${NC}"
    echo -e "  ${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    blank
}

# ── PREGUNTA SÍ/NO / YES/NO PROMPT ────────────────────────────────────────────
ask_yn() {
    local question=$1
    local answer
    blank
    echo -e "  ${BOLD}$question${NC}"
    while true; do
        read -rp "  → $TXT_YES_NO_PROMPT " answer
        answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
        case "$answer" in
            y|yes|s|si|sí) return 0 ;;
            n|no)           return 1 ;;
            *)              echo -e "  ${YELLOW}$TXT_INVALID_YN${NC}" ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# ── SELECCIÓN DE IDIOMA / LANGUAGE SELECTION ──────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
select_language() {
    clear
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║                                                      ║"
    echo "  ║               VPS HARDENER  v1.0                     ║"
    echo "  ║                                                      ║"
    echo "  ╠══════════════════════════════════════════════════════╣"
    echo "  ║                                                      ║"
    echo "  ║      Selecciona un idioma / Choose a language        ║"
    echo "  ║                                                      ║"
    echo "  ║          [1]  Español                                ║"
    echo "  ║          [2]  English                                ║"
    echo "  ║                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo ""
    while true; do
        read -rp "  → " choice
        case $choice in
            1) LANG_CODE="es"; break ;;
            2) LANG_CODE="en"; break ;;
            *) echo "  ✘  Opción inválida / Invalid option (1 o/or 2)" ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# ── TEXTOS DEL IDIOMA / LANGUAGE STRINGS ──────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
setup_language() {

if [[ "$LANG_CODE" == "es" ]]; then

    TXT_YES_CHAR="s"
    TXT_YES_NO_PROMPT="[s/n]:"
    TXT_INVALID_YN="Por favor escribe 's' para sí o 'n' para no."
    TXT_PRESS_ENTER="Presiona ENTER para continuar..."
    TXT_STEP_LABEL="PASO"
    TXT_STEP_OF="de"
    TXT_SKIPPED="Paso omitido."
    TXT_ALREADY_DONE="Ya estaba configurado, se omite."

    # Bienvenida
    TXT_WELCOME_TITLE="¡Bienvenido a VPS Hardener!"
    TXT_WELCOME_2="Este programa te guía paso a paso para asegurar tu servidor."
    TXT_WELCOME_3="Cada paso te explica qué hace ANTES de ejecutar cualquier cosa."
    TXT_WELCOME_4="Puedes saltar cualquier paso que no necesites."
    TXT_WELCOME_WARN="Este script necesita ejecutarse como administrador (root)."
    TXT_WELCOME_LOG="Se guardará un registro de todo en:"

    # Verificaciones
    TXT_ROOT_ERR_1="Este script debe ejecutarse con privilegios de administrador (root)."
    TXT_ROOT_ERR_2="Vuelve a intentarlo con:  sudo bash harden.sh"
    TXT_OS_CHECKING="Detectando sistema operativo..."
    TXT_OS_OK="Sistema detectado:"
    TXT_OS_ERR="Este script solo funciona en Ubuntu y Debian."

    # ── Paso 1: Actualizar
    TXT_S1_TITLE="Actualizar el sistema"
    TXT_S1_WHAT="¿Qué vamos a hacer?"
    TXT_S1_D1="  • Descargar la lista de programas disponibles."
    TXT_S1_D2="  • Instalar todas las actualizaciones de seguridad."
    TXT_S1_D3="Un sistema desactualizado tiene brechas conocidas que los"
    TXT_S1_D4="atacantes aprovechan. Mantenerlo al día es la defensa básica."
    TXT_S1_ASK="¿Deseas actualizar el sistema ahora?"
    TXT_S1_RUNNING="Actualizando paquetes... (puede tardar unos minutos)"
    TXT_S1_OK="Sistema actualizado correctamente."

    # ── Paso 2: Usuario
    TXT_S2_TITLE="Crear usuario administrador"
    TXT_S2_WHAT="¿Por qué no usar root directamente?"
    TXT_S2_D1="  • Usar 'root' todo el tiempo es arriesgado: cualquier error"
    TXT_S2_D2="    o ataque tiene acceso total al servidor inmediatamente."
    TXT_S2_D3="  • Con un usuario personal, el atacante debe adivinar"
    TXT_S2_D4="    tu nombre de usuario Y tu contraseña."
    TXT_S2_ASK="¿Deseas crear un nuevo usuario administrador?"
    TXT_S2_USERNAME_ASK="Nombre del nuevo usuario (solo minúsculas, números y _): "
    TXT_S2_USERNAME_ERR="Solo letras minúsculas, números y guiones bajos. Sin espacios."
    TXT_S2_USER_EXISTS="El usuario ya existe. Se verificarán sus permisos."
    TXT_S2_CREATING="Creando usuario..."
    TXT_S2_SET_PASS="Ahora define una contraseña segura para el usuario"
    TXT_S2_PASS_TIP="  (Usa letras, números y símbolos. Mínimo 12 caracteres recomendados)"
    TXT_S2_SUDO_ADDED="Permisos de administrador (sudo) asignados correctamente."
    TXT_S2_DISABLE_ROOT_ASK="¿Deshabilitar el acceso de root por SSH?"
    TXT_S2_DISABLE_ROOT_TIP="  Recomendado. Asegúrate primero de que tu nuevo usuario funciona."
    TXT_S2_ROOT_DISABLED="Acceso de root por SSH deshabilitado."
    TXT_S2_OK="Usuario configurado correctamente."

    # ── Paso 3: SSH
    TXT_S3_TITLE="Configurar SSH (puerta de acceso remoto)"
    TXT_S3_WHAT="¿Qué es SSH y por qué configurarlo?"
    TXT_S3_D1="  • SSH es la 'puerta' de tu servidor. Por defecto usa el puerto 22."
    TXT_S3_D2="  • El puerto 22 recibe miles de ataques automáticos cada día."
    TXT_S3_D3="  • Cambiar el puerto y usar llaves en vez de contraseñas"
    TXT_S3_D4="    hace tu servidor mucho más difícil de atacar."
    TXT_S3_ASK="¿Deseas configurar SSH ahora?"
    TXT_S3_PORT_WHAT="Cambiar el puerto SSH"
    TXT_S3_PORT_D1="  El puerto por defecto es 22. Cambiarlo a otro número"
    TXT_S3_PORT_D2="  reduce drásticamente los ataques automáticos."
    TXT_S3_PORT_ASK="Número de puerto para SSH (entre 1024 y 65535)"
    TXT_S3_PORT_TIP="  Presiona ENTER para usar 2222 (recomendado): "
    TXT_S3_PORT_INVALID="El puerto debe ser un número entre 1024 y 65535."
    TXT_S3_PORT_SET="Puerto SSH configurado en:"
    TXT_S3_WARN_TITLE="⚠  IMPORTANTE — Lee esto antes de continuar"
    TXT_S3_WARN_1="Después de cambiar el puerto, conéctate al servidor así:"
    TXT_S3_WARN_2="   ssh -p PUERTO_NUEVO tu_usuario@IP_del_servidor"
    TXT_S3_WARN_3="Si cierras esta sesión sin anotar el nuevo puerto, podrías"
    TXT_S3_WARN_4="perder el acceso al servidor. ¡Anótalo ahora!"
    TXT_S3_PUBKEY_WHAT="Autenticación por llave SSH (más seguro que contraseña)"
    TXT_S3_PUBKEY_D1="  Una llave SSH es como una cerradura digital: solo quien tenga"
    TXT_S3_PUBKEY_D2="  la llave privada puede entrar, aunque sepa la contraseña."
    TXT_S3_PUBKEY_ASK="¿Deseas agregar tu llave SSH pública?"
    TXT_S3_PUBKEY_TIP="  (Necesitas tener tu llave pública a mano)"
    TXT_S3_PUBKEY_USER="¿Para qué usuario agregar la llave?"
    TXT_S3_PUBKEY_USER_TIP="  Presiona ENTER para usar"
    TXT_S3_PUBKEY_PASTE="Pega tu llave pública SSH y presiona ENTER:"
    TXT_S3_PUBKEY_FORMAT="  (Empieza con: ssh-rsa, ssh-ed25519, ecdsa-sha2-nistp256...)"
    TXT_S3_PUBKEY_INVALID="Llave inválida. Debe comenzar con ssh-rsa, ssh-ed25519 u otro tipo válido."
    TXT_S3_PUBKEY_OK="Llave pública agregada correctamente."
    TXT_S3_DISPASS_ASK="¿Deshabilitar autenticación por contraseña en SSH?"
    TXT_S3_DISPASS_TIP="  ⚠  Solo hazlo si ya configuraste tu llave SSH y verificaste que funciona."
    TXT_S3_PASS_DISABLED="Autenticación por contraseña deshabilitada en SSH."
    TXT_S3_BACKING_UP="Creando respaldo de la configuración SSH actual..."
    TXT_S3_BACKUP_OK="Respaldo guardado en /etc/ssh/sshd_config.bak"
    TXT_S3_TESTING="Verificando que la configuración SSH sea válida..."
    TXT_S3_TEST_OK="Configuración SSH verificada correctamente."
    TXT_S3_TEST_ERR="Error en la configuración. Restaurando el respaldo automáticamente..."
    TXT_S3_RESTARTING="Reiniciando el servicio SSH..."
    TXT_S3_SOCKET_CHECK="Verificando si el sistema usa socket activation (Ubuntu 22.04+)..."
    TXT_S3_SOCKET_FOUND="Socket SSH detectado. Desactivándolo para que no interfiera con el nuevo puerto..."
    TXT_S3_SOCKET_OK="Socket SSH desactivado. El servicio tomará control del puerto."
    TXT_S3_PORT_VERIFY="Verificando que SSH está escuchando en el puerto"
    TXT_S3_PORT_OK="SSH confirmado escuchando en el puerto"
    TXT_S3_PORT_FAIL="Advertencia: no se pudo confirmar que SSH escucha en el puerto"
    TXT_S3_OK="SSH configurado y reiniciado correctamente."
    TXT_S3_FINAL_1="Recuerda: ahora debes conectarte con:"
    TXT_S3_FINAL_2="Si configuraste un usuario nuevo, usa ese en lugar de root."

    # ── Paso 4: UFW
    TXT_S4_TITLE="Configurar Firewall (UFW)"
    TXT_S4_WHAT="¿Qué es un firewall y para qué sirve?"
    TXT_S4_D1="  • Un firewall decide qué conexiones pueden entrar a tu servidor."
    TXT_S4_D2="  • Sin firewall, todos los puertos están abiertos al mundo."
    TXT_S4_D3="  • Vamos a bloquear todo y abrir solo lo estrictamente necesario."
    TXT_S4_ASK="¿Deseas configurar el firewall UFW?"
    TXT_S4_SSH_INFO="Se abrirá automáticamente el puerto SSH que configuraste:"
    TXT_S4_HTTP_ASK="¿Tu servidor va a alojar un sitio web? (abre puertos 80 y 443)"
    TXT_S4_CONFIGURING="Configurando reglas del firewall..."
    TXT_S4_ENABLING="Activando el firewall... (se pedirá confirmación automáticamente)"
    TXT_S4_OK="Firewall UFW activado correctamente."
    TXT_S4_STATUS="Estado actual del firewall:"

    # ── Paso 5: Fail2ban
    TXT_S5_TITLE="Instalar Fail2ban (protección anti-ataques)"
    TXT_S5_WHAT="¿Qué hace Fail2ban?"
    TXT_S5_D1="  • Monitorea los intentos de acceso fallidos al servidor."
    TXT_S5_D2="  • Si alguien falla demasiadas veces, bloquea su IP automáticamente."
    TXT_S5_D3="  • Es como un portero que expulsa a quien sigue intentando"
    TXT_S5_D4="    entrar sin permiso."
    TXT_S5_ASK="¿Deseas instalar Fail2ban?"
    TXT_S5_INSTALLING="Instalando Fail2ban..."
    TXT_S5_CONFIGURING="Configurando protección para SSH..."
    TXT_S5_OK="Fail2ban activo. Las IPs atacantes serán bloqueadas automáticamente."

    # ── Paso 6: Auto-updates
    TXT_S6_TITLE="Actualizaciones automáticas de seguridad"
    TXT_S6_WHAT="¿Por qué activar actualizaciones automáticas?"
    TXT_S6_D1="  • Los atacantes explotan vulnerabilidades recién descubiertas."
    TXT_S6_D2="  • Las actualizaciones de seguridad cierran esas brechas."
    TXT_S6_D3="  • Solo se instalan parches de seguridad, no versiones nuevas"
    TXT_S6_D4="    que puedan romper algo."
    TXT_S6_ASK="¿Deseas activar las actualizaciones automáticas de seguridad?"
    TXT_S6_INSTALLING="Instalando y configurando actualizaciones automáticas..."
    TXT_S6_OK="Actualizaciones automáticas de seguridad activadas."

    # ── Paso 7: Timezone
    TXT_S7_TITLE="Configurar zona horaria"
    TXT_S7_WHAT="¿Por qué importa la zona horaria?"
    TXT_S7_D1="  • Los logs del servidor registran exactamente cuándo ocurre cada evento."
    TXT_S7_D2="  • Con la zona horaria incorrecta, los horarios no coinciden con"
    TXT_S7_D3="    la realidad y es más difícil detectar o investigar incidentes."
    TXT_S7_ASK="¿Deseas configurar la zona horaria?"
    TXT_S7_CURRENT="Zona horaria actual del servidor:"
    TXT_S7_INPUT="Escribe tu zona horaria"
    TXT_S7_EXAMPLES="  Ejemplos: America/Santiago  America/Mexico_City  Europe/Madrid"
    TXT_S7_ENTER_TIP="  Presiona ENTER para elegir de una lista interactiva: "
    TXT_S7_INTERACTIVE="Abriendo selector interactivo de zona horaria..."
    TXT_S7_INVALID="Zona horaria no reconocida. Usando el selector interactivo..."
    TXT_S7_OK="Zona horaria configurada correctamente."

    # Resumen
    TXT_SUM_TITLE="PROCESO COMPLETADO"
    TXT_SUM_DONE="Pasos completados:"
    TXT_SUM_SKIPPED="Pasos omitidos:"
    TXT_SUM_NEXT="Próximos pasos recomendados:"
    TXT_SUM_N1="Prueba conectarte con tu nuevo usuario y puerto ANTES de cerrar esta sesión."
    TXT_SUM_N2="Cuando estés seguro de que todo funciona, reinicia el servidor:"
    TXT_SUM_N3="    sudo reboot"
    TXT_SUM_LOG="Registro completo guardado en:"
    TXT_SUM_THANKS="¡Gracias por usar VPS Hardener! Tu servidor ahora es más seguro."

else
    # ── ENGLISH ───────────────────────────────────────────────────────────────

    TXT_YES_CHAR="y"
    TXT_YES_NO_PROMPT="[y/n]:"
    TXT_INVALID_YN="Please type 'y' for yes or 'n' for no."
    TXT_PRESS_ENTER="Press ENTER to continue..."
    TXT_STEP_LABEL="STEP"
    TXT_STEP_OF="of"
    TXT_SKIPPED="Step skipped."
    TXT_ALREADY_DONE="Already configured, skipping."

    TXT_WELCOME_TITLE="Welcome to VPS Hardener!"
    TXT_WELCOME_2="This program guides you step by step to secure your server."
    TXT_WELCOME_3="Each step explains what it does BEFORE running anything."
    TXT_WELCOME_4="You can skip any step you don't need."
    TXT_WELCOME_WARN="This script must be run as administrator (root)."
    TXT_WELCOME_LOG="A full log of all actions will be saved to:"

    TXT_ROOT_ERR_1="This script must be run with administrator (root) privileges."
    TXT_ROOT_ERR_2="Try again with:  sudo bash harden.sh"
    TXT_OS_CHECKING="Detecting operating system..."
    TXT_OS_OK="Detected system:"
    TXT_OS_ERR="This script only works on Ubuntu and Debian."

    TXT_S1_TITLE="Update the system"
    TXT_S1_WHAT="What we are going to do:"
    TXT_S1_D1="  • Download the updated list of available packages."
    TXT_S1_D2="  • Install all available security updates."
    TXT_S1_D3="An outdated system has known vulnerabilities that attackers"
    TXT_S1_D4="actively exploit. Keeping it updated is the most basic defense."
    TXT_S1_ASK="Do you want to update the system now?"
    TXT_S1_RUNNING="Updating packages... (this may take a few minutes)"
    TXT_S1_OK="System updated successfully."

    TXT_S2_TITLE="Create admin user"
    TXT_S2_WHAT="Why not just use root?"
    TXT_S2_D1="  • Using 'root' directly is risky: any mistake or attack gets"
    TXT_S2_D2="    immediate, unrestricted access to everything on the server."
    TXT_S2_D3="  • With a personal user, an attacker must guess both"
    TXT_S2_D4="    your username AND your password."
    TXT_S2_ASK="Do you want to create a new admin user?"
    TXT_S2_USERNAME_ASK="New username (lowercase letters, numbers and _ only): "
    TXT_S2_USERNAME_ERR="Only lowercase letters, numbers and underscores. No spaces."
    TXT_S2_USER_EXISTS="User already exists. Checking permissions."
    TXT_S2_CREATING="Creating user..."
    TXT_S2_SET_PASS="Now set a strong password for user"
    TXT_S2_PASS_TIP="  (Use letters, numbers and symbols. At least 12 characters recommended)"
    TXT_S2_SUDO_ADDED="Administrator (sudo) permissions granted successfully."
    TXT_S2_DISABLE_ROOT_ASK="Disable direct root login via SSH?"
    TXT_S2_DISABLE_ROOT_TIP="  Recommended. Make sure your new user works before doing this."
    TXT_S2_ROOT_DISABLED="Root SSH login disabled."
    TXT_S2_OK="User configured successfully."

    TXT_S3_TITLE="Configure SSH (remote access door)"
    TXT_S3_WHAT="What is SSH and why configure it?"
    TXT_S3_D1="  • SSH is the 'door' to your server. It uses port 22 by default."
    TXT_S3_D2="  • Port 22 receives thousands of automated attacks every single day."
    TXT_S3_D3="  • Changing the port and using keys instead of passwords"
    TXT_S3_D4="    makes your server much harder to attack."
    TXT_S3_ASK="Do you want to configure SSH now?"
    TXT_S3_PORT_WHAT="Changing the SSH port"
    TXT_S3_PORT_D1="  The default port is 22. Changing it to another number"
    TXT_S3_PORT_D2="  dramatically reduces automated attacks."
    TXT_S3_PORT_ASK="SSH port number (between 1024 and 65535)"
    TXT_S3_PORT_TIP="  Press ENTER to use 2222 (recommended): "
    TXT_S3_PORT_INVALID="Port must be a number between 1024 and 65535."
    TXT_S3_PORT_SET="SSH port set to:"
    TXT_S3_WARN_TITLE="⚠  IMPORTANT — Read this before continuing"
    TXT_S3_WARN_1="After changing the port, connect to the server like this:"
    TXT_S3_WARN_2="   ssh -p NEW_PORT your_user@server_IP"
    TXT_S3_WARN_3="If you close this session without noting the new port, you"
    TXT_S3_WARN_4="may lose access to your server. Write the port number down NOW!"
    TXT_S3_PUBKEY_WHAT="SSH key authentication (more secure than passwords)"
    TXT_S3_PUBKEY_D1="  An SSH key is like a digital lock: only whoever has the"
    TXT_S3_PUBKEY_D2="  private key can enter, even if they know the password."
    TXT_S3_PUBKEY_ASK="Do you want to add your SSH public key?"
    TXT_S3_PUBKEY_TIP="  (You need your public key ready)"
    TXT_S3_PUBKEY_USER="Which user should the key be added for?"
    TXT_S3_PUBKEY_USER_TIP="  Press ENTER to use"
    TXT_S3_PUBKEY_PASTE="Paste your SSH public key and press ENTER:"
    TXT_S3_PUBKEY_FORMAT="  (Starts with: ssh-rsa, ssh-ed25519, ecdsa-sha2-nistp256...)"
    TXT_S3_PUBKEY_INVALID="Invalid key. Must start with ssh-rsa, ssh-ed25519 or another valid type."
    TXT_S3_PUBKEY_OK="Public key added successfully."
    TXT_S3_DISPASS_ASK="Disable password authentication for SSH?"
    TXT_S3_DISPASS_TIP="  ⚠  Only do this if you have set up your SSH key and verified it works."
    TXT_S3_PASS_DISABLED="Password authentication disabled for SSH."
    TXT_S3_BACKING_UP="Creating a backup of the current SSH configuration..."
    TXT_S3_BACKUP_OK="Backup saved to /etc/ssh/sshd_config.bak"
    TXT_S3_TESTING="Verifying the SSH configuration is valid..."
    TXT_S3_TEST_OK="SSH configuration verified successfully."
    TXT_S3_TEST_ERR="Configuration error found. Automatically restoring backup..."
    TXT_S3_RESTARTING="Restarting SSH service..."
    TXT_S3_SOCKET_CHECK="Checking if the system uses socket activation (Ubuntu 22.04+)..."
    TXT_S3_SOCKET_FOUND="SSH socket detected. Disabling it so it does not override the new port..."
    TXT_S3_SOCKET_OK="SSH socket disabled. The service will now control the port directly."
    TXT_S3_PORT_VERIFY="Verifying that SSH is listening on port"
    TXT_S3_PORT_OK="SSH confirmed listening on port"
    TXT_S3_PORT_FAIL="Warning: could not confirm SSH is listening on port"
    TXT_S3_OK="SSH configured and restarted successfully."
    TXT_S3_FINAL_1="Remember: connect to your server using:"
    TXT_S3_FINAL_2="If you created a new user, use that instead of root."

    TXT_S4_TITLE="Configure Firewall (UFW)"
    TXT_S4_WHAT="What is a firewall and why set one up?"
    TXT_S4_D1="  • A firewall decides which connections can reach your server."
    TXT_S4_D2="  • Without a firewall, all ports are open to the internet."
    TXT_S4_D3="  • We will block everything and only open what is needed."
    TXT_S4_ASK="Do you want to configure the UFW firewall?"
    TXT_S4_SSH_INFO="Your configured SSH port will be opened automatically:"
    TXT_S4_HTTP_ASK="Will your server host a website? (opens ports 80 and 443)"
    TXT_S4_CONFIGURING="Configuring firewall rules..."
    TXT_S4_ENABLING="Enabling the firewall..."
    TXT_S4_OK="UFW firewall enabled successfully."
    TXT_S4_STATUS="Current firewall status:"

    TXT_S5_TITLE="Install Fail2ban (brute force protection)"
    TXT_S5_WHAT="What does Fail2ban do?"
    TXT_S5_D1="  • It monitors failed login attempts on your server."
    TXT_S5_D2="  • If someone fails too many times, their IP is blocked automatically."
    TXT_S5_D3="  • Think of it as a bouncer who permanently bans anyone"
    TXT_S5_D4="    who keeps trying to get in without permission."
    TXT_S5_ASK="Do you want to install Fail2ban?"
    TXT_S5_INSTALLING="Installing Fail2ban..."
    TXT_S5_CONFIGURING="Configuring SSH protection..."
    TXT_S5_OK="Fail2ban is active. Attacking IPs will be blocked automatically."

    TXT_S6_TITLE="Automatic security updates"
    TXT_S6_WHAT="Why enable automatic updates?"
    TXT_S6_D1="  • Attackers exploit newly discovered vulnerabilities quickly."
    TXT_S6_D2="  • Security updates close those vulnerabilities automatically."
    TXT_S6_D3="  • Only security patches are installed — not major new versions"
    TXT_S6_D4="    that could break something."
    TXT_S6_ASK="Do you want to enable automatic security updates?"
    TXT_S6_INSTALLING="Installing and configuring automatic updates..."
    TXT_S6_OK="Automatic security updates enabled."

    TXT_S7_TITLE="Configure timezone"
    TXT_S7_WHAT="Why does the timezone matter?"
    TXT_S7_D1="  • Server logs record exactly when each event happens."
    TXT_S7_D2="  • With the wrong timezone, log timestamps don't match reality,"
    TXT_S7_D3="    making it harder to detect or investigate security incidents."
    TXT_S7_ASK="Do you want to configure the timezone?"
    TXT_S7_CURRENT="Current server timezone:"
    TXT_S7_INPUT="Enter your timezone"
    TXT_S7_EXAMPLES="  Examples: America/New_York  Europe/London  Asia/Tokyo"
    TXT_S7_ENTER_TIP="  Press ENTER to choose from an interactive list: "
    TXT_S7_INTERACTIVE="Opening interactive timezone selector..."
    TXT_S7_INVALID="Timezone not recognized. Opening interactive selector..."
    TXT_S7_OK="Timezone configured successfully."

    TXT_SUM_TITLE="PROCESS COMPLETE"
    TXT_SUM_DONE="Completed steps:"
    TXT_SUM_SKIPPED="Skipped steps:"
    TXT_SUM_NEXT="Recommended next steps:"
    TXT_SUM_N1="Test connecting with your new user and port BEFORE closing this session."
    TXT_SUM_N2="Once you confirm everything works, reboot the server:"
    TXT_SUM_N3="    sudo reboot"
    TXT_SUM_LOG="Full log saved to:"
    TXT_SUM_THANKS="Thank you for using VPS Hardener! Your server is now more secure."

fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ── BIENVENIDA / WELCOME ──────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
show_welcome() {
    clear
    blank
    echo -e "  ${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${BOLD}${GREEN}║                                                      ║${NC}"
    echo -e "  ${BOLD}${GREEN}║             VPS HARDENER  v1.0                       ║${NC}"
    echo -e "  ${BOLD}${GREEN}║                                                      ║${NC}"
    echo -e "  ${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    blank
    echo -e "  ${BOLD}$TXT_WELCOME_TITLE${NC}"
    blank
    echo -e "  $TXT_WELCOME_2"
    echo -e "  $TXT_WELCOME_3"
    echo -e "  $TXT_WELCOME_4"
    blank
    warning "$TXT_WELCOME_WARN"
    blank
    echo -e "  ${DIM}$TXT_WELCOME_LOG $LOG_FILE${NC}"
    blank
    press_enter
}

# ── VERIFICACIONES INICIALES / INITIAL CHECKS ─────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        clear
        blank
        error "$TXT_ROOT_ERR_1"
        blank
        echo -e "  ${YELLOW}$TXT_ROOT_ERR_2${NC}"
        blank
        exit 1
    fi
}

check_os() {
    info "$TXT_OS_CHECKING"
    if [[ ! -f /etc/os-release ]]; then
        error "$TXT_OS_ERR"
        exit 1
    fi
    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        error "$TXT_OS_ERR"
        blank
        exit 1
    fi
    success "$TXT_OS_OK $PRETTY_NAME"
    _log "OS: $PRETTY_NAME"
    sleep 1
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 1 / STEP 1: ACTUALIZAR / UPDATE ──────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step1_update() {
    step_header 1 "$TXT_S1_TITLE"

    echo -e "  ${BOLD}$TXT_S1_WHAT${NC}"
    blank
    echo -e "$TXT_S1_D1"
    echo -e "$TXT_S1_D2"
    blank
    echo -e "  ${DIM}$TXT_S1_D3"
    echo -e "  $TXT_S1_D4${NC}"
    line

    if ask_yn "$TXT_S1_ASK"; then
        blank
        info "$TXT_S1_RUNNING"
        blank
        apt-get update
        apt-get upgrade -y
        blank
        success "$TXT_S1_OK"
        STEPS_DONE+=("$TXT_S1_TITLE")
    else
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S1_TITLE")
    fi

    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 2 / STEP 2: USUARIO / USER ───────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step2_user() {
    step_header 2 "$TXT_S2_TITLE"

    echo -e "  ${BOLD}$TXT_S2_WHAT${NC}"
    blank
    echo -e "$TXT_S2_D1"
    echo -e "$TXT_S2_D2"
    echo -e "$TXT_S2_D3"
    echo -e "$TXT_S2_D4"
    line

    if ! ask_yn "$TXT_S2_ASK"; then
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S2_TITLE")
        press_enter
        return
    fi

    # Pedir nombre de usuario / Ask for username
    local username
    while true; do
        blank
        read -rp "  → $TXT_S2_USERNAME_ASK" username
        if [[ "$username" =~ ^[a-z][a-z0-9_]{1,30}$ ]]; then
            break
        else
            error "$TXT_S2_USERNAME_ERR"
        fi
    done
    NEW_USERNAME="$username"
    _log "New user: $username"

    blank
    if id "$username" &>/dev/null; then
        warning "$TXT_S2_USER_EXISTS"
    else
        info "$TXT_S2_CREATING"
        adduser --gecos "" --disabled-password "$username"
        blank
        echo -e "  ${BOLD}$TXT_S2_SET_PASS '$username':${NC}"
        echo -e "  ${DIM}$TXT_S2_PASS_TIP${NC}"
        blank
        passwd "$username"
    fi

    # Agregar a sudo / Add to sudo
    usermod -aG sudo "$username"
    success "$TXT_S2_SUDO_ADDED"

    # Deshabilitar root en SSH / Disable root SSH
    line
    blank
    echo -e "  ${DIM}$TXT_S2_DISABLE_ROOT_TIP${NC}"
    if ask_yn "$TXT_S2_DISABLE_ROOT_ASK"; then
        if grep -qE "^#?PermitRootLogin" /etc/ssh/sshd_config; then
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
        else
            echo "PermitRootLogin no" >> /etc/ssh/sshd_config
        fi
        success "$TXT_S2_ROOT_DISABLED"
        _log "PermitRootLogin set to no"
    fi

    blank
    success "$TXT_S2_OK"
    STEPS_DONE+=("$TXT_S2_TITLE ($username)")
    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 3 / STEP 3: SSH ──────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step3_ssh() {
    step_header 3 "$TXT_S3_TITLE"

    echo -e "  ${BOLD}$TXT_S3_WHAT${NC}"
    blank
    echo -e "$TXT_S3_D1"
    echo -e "$TXT_S3_D2"
    echo -e "$TXT_S3_D3"
    echo -e "$TXT_S3_D4"
    line

    if ! ask_yn "$TXT_S3_ASK"; then
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S3_TITLE")
        press_enter
        return
    fi

    # Respaldo de sshd_config / Backup sshd_config
    blank
    info "$TXT_S3_BACKING_UP"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    success "$TXT_S3_BACKUP_OK"

    # ── Cambiar puerto / Change port ──────────────────────────────────────────
    blank
    line
    echo -e "  ${BOLD}$TXT_S3_PORT_WHAT${NC}"
    blank
    echo -e "$TXT_S3_PORT_D1"
    echo -e "$TXT_S3_PORT_D2"
    blank
    echo -e "  ${BOLD}$TXT_S3_PORT_ASK${NC}"

    local port
    while true; do
        read -rp "$TXT_S3_PORT_TIP" port
        port="${port:-2222}"
        if [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1024 && port <= 65535 )); then
            break
        else
            error "$TXT_S3_PORT_INVALID"
        fi
    done
    SSH_PORT="$port"
    _log "SSH port: $SSH_PORT"

    blank
    success "$TXT_S3_PORT_SET $SSH_PORT"
    blank

    # Advertencia sobre el puerto / Port change warning
    echo -e "  ${YELLOW}${BOLD}  $TXT_S3_WARN_TITLE  ${NC}"
    blank
    echo -e "  ${YELLOW}  $TXT_S3_WARN_1${NC}"
    echo -e "  ${YELLOW}${BOLD}  ssh -p $SSH_PORT ${NEW_USERNAME:-TU_USUARIO}@IP_DEL_SERVIDOR${NC}"
    blank
    echo -e "  ${YELLOW}  $TXT_S3_WARN_3${NC}"
    echo -e "  ${YELLOW}${BOLD}  $TXT_S3_WARN_4${NC}"
    press_enter

    # Aplicar cambio de puerto / Apply port change
    if grep -qE "^#?Port " /etc/ssh/sshd_config; then
        sed -i "s/^#*Port .*/Port $SSH_PORT/" /etc/ssh/sshd_config
    else
        echo "Port $SSH_PORT" >> /etc/ssh/sshd_config
    fi

    # ── Llave pública / Public key ────────────────────────────────────────────
    line
    blank
    echo -e "  ${BOLD}$TXT_S3_PUBKEY_WHAT${NC}"
    blank
    echo -e "$TXT_S3_PUBKEY_D1"
    echo -e "$TXT_S3_PUBKEY_D2"
    blank
    echo -e "  ${DIM}$TXT_S3_PUBKEY_TIP${NC}"

    if ask_yn "$TXT_S3_PUBKEY_ASK"; then
        local target_user="${NEW_USERNAME:-root}"
        blank
        echo -e "  ${BOLD}$TXT_S3_PUBKEY_USER${NC}"
        echo -e "  ${DIM}$TXT_S3_PUBKEY_USER_TIP '$target_user': ${NC}"
        read -rp "  → " input_user
        [[ -n "$input_user" ]] && target_user="$input_user"

        local home_dir
        home_dir=$(getent passwd "$target_user" | cut -d: -f6)

        if [[ -z "$home_dir" ]]; then
            error "User '$target_user' not found."
        else
            blank
            echo -e "  $TXT_S3_PUBKEY_PASTE"
            echo -e "  ${DIM}$TXT_S3_PUBKEY_FORMAT${NC}"
            blank

            local pubkey
            read -r pubkey

            if [[ "$pubkey" =~ ^(ssh-rsa|ssh-ed25519|ssh-dss|ecdsa-sha2-nistp|sk-ssh) ]]; then
                mkdir -p "$home_dir/.ssh"
                echo "$pubkey" >> "$home_dir/.ssh/authorized_keys"
                chmod 700 "$home_dir/.ssh"
                chmod 600 "$home_dir/.ssh/authorized_keys"
                chown -R "$target_user:$target_user" "$home_dir/.ssh"
                success "$TXT_S3_PUBKEY_OK"
                _log "Public key added for $target_user"
            else
                error "$TXT_S3_PUBKEY_INVALID"
            fi
        fi
    fi

    # ── Deshabilitar contraseña / Disable password auth ───────────────────────
    line
    blank
    echo -e "  ${YELLOW}$TXT_S3_DISPASS_TIP${NC}"

    if ask_yn "$TXT_S3_DISPASS_ASK"; then
        if grep -qE "^#?PasswordAuthentication" /etc/ssh/sshd_config; then
            sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
        else
            echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
        fi
        success "$TXT_S3_PASS_DISABLED"
        _log "PasswordAuthentication disabled"
    fi

    # ── Verificar configuración / Validate config ─────────────────────────────
    blank
    info "$TXT_S3_TESTING"
    if ! sshd -t 2>/dev/null; then
        error "$TXT_S3_TEST_ERR"
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null || systemctl restart ssh
        warning "SSH configuration restored to original."
        _log "SSH config restored from backup due to error"
        press_enter
        return
    fi
    success "$TXT_S3_TEST_OK"

    # ── Desactivar socket si existe / Disable socket if present ─────────────────
    # ssh.socket toma control del puerto directamente e ignora sshd_config.
    # La solución definitiva es desactivarlo y dejar que ssh.service maneje todo.
    blank
    info "$TXT_S3_SOCKET_CHECK"
    if systemctl is-active ssh.socket &>/dev/null || systemctl is-enabled ssh.socket &>/dev/null 2>/dev/null; then
        info "$TXT_S3_SOCKET_FOUND"
        systemctl stop ssh.socket
        systemctl disable ssh.socket
        success "$TXT_S3_SOCKET_OK"
        _log "ssh.socket stopped and disabled"
    fi

    # ── Reiniciar servicio / Restart service ──────────────────────────────────
    blank
    info "$TXT_S3_RESTARTING"
    systemctl restart ssh
    sleep 2

    # ── Comprobar que escucha en el puerto / Verify listening port ────────────
    blank
    info "$TXT_S3_PORT_VERIFY $SSH_PORT..."
    if ss -tlnp | grep -q ":$SSH_PORT "; then
        success "$TXT_S3_PORT_OK $SSH_PORT."
        _log "SSH listening confirmed on port $SSH_PORT"
    else
        warning "$TXT_S3_PORT_FAIL $SSH_PORT."
        _log "Could not confirm SSH listening on port $SSH_PORT"
    fi

    success "$TXT_S3_OK"

    blank
    line
    echo -e "  ${YELLOW}${BOLD}  $TXT_S3_FINAL_1${NC}"
    echo -e "  ${YELLOW}${BOLD}  ssh -p $SSH_PORT ${NEW_USERNAME:-root}@<IP>${NC}"
    blank
    echo -e "  ${DIM}  $TXT_S3_FINAL_2${NC}"

    STEPS_DONE+=("$TXT_S3_TITLE (port $SSH_PORT)")
    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 4 / STEP 4: UFW ──────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step4_ufw() {
    step_header 4 "$TXT_S4_TITLE"

    echo -e "  ${BOLD}$TXT_S4_WHAT${NC}"
    blank
    echo -e "$TXT_S4_D1"
    echo -e "$TXT_S4_D2"
    echo -e "$TXT_S4_D3"
    line

    if ! ask_yn "$TXT_S4_ASK"; then
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S4_TITLE")
        press_enter
        return
    fi

    # Instalar UFW si no está / Install UFW if missing
    if ! command -v ufw &>/dev/null; then
        apt-get install -y ufw -qq
    fi

    blank
    info "$TXT_S4_CONFIGURING"

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing

    # Puerto SSH / SSH port
    blank
    echo -e "  ${CYAN}  ✦  $TXT_S4_SSH_INFO ${BOLD}$SSH_PORT${NC}"
    ufw allow "$SSH_PORT"/tcp comment 'SSH'
    _log "UFW: opened port $SSH_PORT (SSH)"

    # Puertos web / Web ports
    line
    if ask_yn "$TXT_S4_HTTP_ASK"; then
        ufw allow 80/tcp comment 'HTTP'
        ufw allow 443/tcp comment 'HTTPS'
        info "HTTP (80) + HTTPS (443) opened."
        _log "UFW: opened ports 80 and 443 (web)"
    fi

    # Activar / Enable
    blank
    info "$TXT_S4_ENABLING"
    echo "y" | ufw enable

    blank
    success "$TXT_S4_OK"
    blank
    echo -e "  ${BOLD}$TXT_S4_STATUS${NC}"
    blank
    ufw status verbose

    STEPS_DONE+=("$TXT_S4_TITLE")
    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 5 / STEP 5: FAIL2BAN ─────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step5_fail2ban() {
    step_header 5 "$TXT_S5_TITLE"

    echo -e "  ${BOLD}$TXT_S5_WHAT${NC}"
    blank
    echo -e "$TXT_S5_D1"
    echo -e "$TXT_S5_D2"
    blank
    echo -e "  ${DIM}$TXT_S5_D3"
    echo -e "  $TXT_S5_D4${NC}"
    line

    if ! ask_yn "$TXT_S5_ASK"; then
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S5_TITLE")
        press_enter
        return
    fi

    blank
    info "$TXT_S5_INSTALLING"
    apt-get install -y fail2ban -qq

    blank
    info "$TXT_S5_CONFIGURING"

    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8

[sshd]
enabled  = true
port     = $SSH_PORT
maxretry = 3
bantime  = 2h
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban

    blank
    success "$TXT_S5_OK"
    _log "Fail2ban installed and configured for port $SSH_PORT"

    STEPS_DONE+=("$TXT_S5_TITLE")
    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 6 / STEP 6: AUTO-UPDATES ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step6_auto_updates() {
    step_header 6 "$TXT_S6_TITLE"

    echo -e "  ${BOLD}$TXT_S6_WHAT${NC}"
    blank
    echo -e "$TXT_S6_D1"
    echo -e "$TXT_S6_D2"
    blank
    echo -e "  ${DIM}$TXT_S6_D3"
    echo -e "  $TXT_S6_D4${NC}"
    line

    if ! ask_yn "$TXT_S6_ASK"; then
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S6_TITLE")
        press_enter
        return
    fi

    blank
    info "$TXT_S6_INSTALLING"
    apt-get install -y unattended-upgrades apt-listchanges -qq

    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Download-Upgradeable-Packages "1";
EOF

    dpkg-reconfigure -f noninteractive unattended-upgrades

    blank
    success "$TXT_S6_OK"
    _log "Automatic security updates enabled"

    STEPS_DONE+=("$TXT_S6_TITLE")
    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── PASO 7 / STEP 7: TIMEZONE ─────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
step7_timezone() {
    step_header 7 "$TXT_S7_TITLE"

    echo -e "  ${BOLD}$TXT_S7_WHAT${NC}"
    blank
    echo -e "$TXT_S7_D1"
    echo -e "$TXT_S7_D2"
    echo -e "$TXT_S7_D3"
    blank

    local current_tz
    current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null \
                 || cat /etc/timezone 2>/dev/null \
                 || echo "unknown")
    info "$TXT_S7_CURRENT $current_tz"
    line

    if ! ask_yn "$TXT_S7_ASK"; then
        warning "$TXT_SKIPPED"
        STEPS_SKIPPED+=("$TXT_S7_TITLE")
        press_enter
        return
    fi

    blank
    echo -e "  ${BOLD}$TXT_S7_INPUT${NC}"
    echo -e "$TXT_S7_EXAMPLES"
    local tz
    read -rp "$TXT_S7_ENTER_TIP" tz

    if [[ -z "$tz" ]]; then
        info "$TXT_S7_INTERACTIVE"
        dpkg-reconfigure tzdata
    else
        if timedatectl set-timezone "$tz" 2>/dev/null; then
            success "$TXT_S7_OK"
            _log "Timezone set to $tz"
        else
            warning "$TXT_S7_INVALID"
            dpkg-reconfigure tzdata
        fi
    fi

    STEPS_DONE+=("$TXT_S7_TITLE")
    press_enter
}

# ══════════════════════════════════════════════════════════════════════════════
# ── RESUMEN FINAL / FINAL SUMMARY ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
show_summary() {
    clear
    blank
    echo -e "  ${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${BOLD}${GREEN}║                                                      ║${NC}"
    echo -e "  ${BOLD}${GREEN}║           ✔  $TXT_SUM_TITLE                          ║${NC}"
    echo -e "  ${BOLD}${GREEN}║                                                      ║${NC}"
    echo -e "  ${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    blank

    if [[ ${#STEPS_DONE[@]} -gt 0 ]]; then
        echo -e "  ${BOLD}${GREEN}$TXT_SUM_DONE${NC}"
        for step in "${STEPS_DONE[@]}"; do
            echo -e "  ${GREEN}    ✔  $step${NC}"
        done
        blank
    fi

    if [[ ${#STEPS_SKIPPED[@]} -gt 0 ]]; then
        echo -e "  ${BOLD}${YELLOW}$TXT_SUM_SKIPPED${NC}"
        for step in "${STEPS_SKIPPED[@]}"; do
            echo -e "  ${YELLOW}    ⏭  $step${NC}"
        done
        blank
    fi

    line
    blank
    echo -e "  ${BOLD}$TXT_SUM_NEXT${NC}"
    blank
    echo -e "  ${CYAN}  1.  $TXT_SUM_N1${NC}"
    blank
    echo -e "  ${CYAN}  2.  $TXT_SUM_N2${NC}"
    echo -e "  ${BOLD}${CYAN}$TXT_SUM_N3${NC}"
    blank
    line
    blank
    echo -e "  ${DIM}$TXT_SUM_LOG $LOG_FILE${NC}"
    blank
    echo -e "  ${BOLD}${GREEN}$TXT_SUM_THANKS${NC}"
    blank
}

# ══════════════════════════════════════════════════════════════════════════════
# ── MAIN ──────────────────────────────────────────────────────────────────────
# ══════════════════════════════════════════════════════════════════════════════
main() {
    select_language
    setup_language
    check_root
    check_os
    show_welcome

    step1_update
    step2_user
    step3_ssh
    step4_ufw
    step5_fail2ban
    step6_auto_updates
    step7_timezone

    show_summary
}

main
