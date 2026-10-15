# Misión Función — versión Cloudflare (Pages + D1)

**Centro Educativo Dos Bocas · Prof. Ofilio Jiménez · Matemática 12°**

## Arquitectura

```
Estudiante (navegador) ──► Cloudflare Worker (+ static assets) ──► D1 (SQLite en la nube)
 index.html + localStorage     src/worker.js: API /api/*             students · level_results · attempts
 (respaldo sin conexión)       public/: sitio estático
```

- **Frontend** (`public/index.html`): el mismo juego y el mismo panel del profesor. Guarda en `localStorage` y además sincroniza con la nube.
- **API** (`src/worker.js`): responde `/api/*`; todo lo demás lo sirve Cloudflare desde `public/`.
- **Base de datos** (`schema.sql`): D1. `students` (identidad = nombre sin tildes ni mayúsculas), `level_results` (resultado vigente por nivel), `attempts` (historial).

### Flujo de datos
| Momento | Qué pasa |
|---|---|
| Al escribir el nombre / empezar | Se trae el progreso de la nube (puedes continuar desde otro dispositivo). |
| Al terminar **cada nivel** | Se guarda automáticamente en la nube (puntaje, nota, fecha, dispositivo). |
| Botón **☁️ Guardar todo el registro en la nube** | Inicio, fin de nivel y pantalla final: sube todos los registros del dispositivo + pendientes. |
| Sin internet | Queda en cola (insignia azul «pendientes») y se envía solo al volver la conexión. |
| Panel del profesor | Misma clave, mismo diseño. Ahora muestra la nube + este dispositivo; el CSV exporta todo. |
| «Borrar todos los registros» | Borra dispositivo **y** nube. |

### API
| Método | Ruta | Acceso |
|---|---|---|
| GET | `/api/health` | público |
| GET | `/api/student?name=` | público (solo ese estudiante) |
| POST | `/api/sync` | público (máx. 50 estudiantes por envío) |
| GET / DELETE | `/api/teacher` | cabecera `x-teacher-key` = clave del docente |

El servidor **recalcula** las notas con la fórmula MEDUCA, ignora puntajes inválidos, nunca deja que un dato viejo pise uno nuevo y limpia los nombres (anti-XSS).

## Despliegue (con wrangler)

Requisito: Node.js 18+ instalado. Abre una terminal dentro de esta carpeta:

```
npm install
npx wrangler login                 # abre el navegador; inicia sesión en Cloudflare
npm run db:create                  # imprime el database_id → pégalo en wrangler.toml
npm run db:schema                  # crea las tablas
npm run secret                     # cuando lo pida, escribe: Ofilio2026
npm run deploy                     # publica; imprime tu URL https://mision-funcion.<cuenta>.workers.dev
```

Antes de `deploy`, copia tus 5 imágenes a `public/img/` (ver `LEEME.txt`).
Verifica: `https://TU-URL/api/health` → `{"ok":true,...}`.

**Sin terminal:** sube esta carpeta a un repositorio de GitHub y en *Workers & Pages → Create → Import a repository* conéctalo (Cloudflare usará `wrangler.toml`). Luego en el Worker → *Settings → Variables and Secrets* agrega `TEACHER_PASS` = `Ofilio2026`.

## Notas
- Ver intentos o exportar desde D1: Console → `SELECT s.name, a.level, a.score, a.created_at FROM attempts a JOIN students s ON s.id=a.student_id ORDER BY a.id DESC;`
- Ya no se necesita `netlify.toml` ni el Apps Script (`code_14102026.js`).
- No pongas el Worker dentro de `public/`: todo lo de esa carpeta es público.
- Recomendado: en *Security → WAF → Rate limiting* limita `/api/*` (p. ej. 60 peticiones/min por IP).
