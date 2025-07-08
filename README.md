# 🌐 Azure Blob Lifecycle Demo

Ejercicio didáctico **end‑to‑end** para mostrar cómo funcionan los tiers **Hot → Cool → Archive** en Azure Blob Storage, optimizado para el entorno gratuito / bajo costo y buenas prácticas FinOps.

> ✅ Probado en **WSL Ubuntu 24.04 LTS** + **Azure CLI ≥ 2.45**.

---

## 🛠️ Prerrequisitos

| Requisito    | Detalle                                                                       |
| ------------ | ----------------------------------------------------------------------------- |
| Azure CLI    | `az version` ≥ 2.45 (2024‑05)                                                 |
| Subscripción | Rol **Contributor** + **Storage Blob Data Contributor** en el alcance deseado |
| WSL distro   | Ubuntu 24.04 LTS (Bash ≥ 5)                                                   |
| Conexión     | Internet para llamar a la API de Azure                                        |

Instala Azure CLI:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login
az account set --subscription "<tu‑subscription‑id>"
```

---

## 📂 Estructura del repositorio

```
azure-blob-lifecycle-demo/
├── scripts/
│   ├── deploy.sh          # Despliega RG + Storage + política
│   ├── test-lifecycle.sh  # Demuestra Hot→Cool→Archive
│   └── destroy.sh         # Limpia todo y espera confirmación
└── README.md              # Este documento
```

---

## 💸 Estimación de costos (1 hora)

| Recurso                                | Cantidad | Precio/hora | Total 1 h      |
| -------------------------------------- | -------- | ----------- | -------------- |
| Storage Standard LRS (≤ 5 GB Hot)      | \~1 MB   | 0 USD\*     | 0,000 USD      |
| Operaciones Put/Get (≈ 20)             | –        | 0 USD\*     | 0,000 USD      |
| Cambios de tier Hot→Cool / Hot→Archive | 2        | 0 USD\*     | 0,000 USD      |
| **Total estimado**                     | –        | –           | **≈ 0,00 USD** |

\* Dentro de la capa gratuita 2025 para cuentas Standard\_LRS en muchas regiones. Comprueba en tu portal Cost Management.

---

## 🚀 Pasos rápidos

```bash
# 1. Clonar o copiar el repo
mkdir azure-blob-lifecycle-demo && cd $_
# (pega aquí los scripts y README)

# 2. Dar permisos de ejecución
chmod +x scripts/*.sh

# 3. Desplegar infraestructura
./scripts/deploy.sh

# 4. Probar ciclo de vida
./scripts/test-lifecycle.sh
   # > Verás los blobs moverse de Hot a Cool y Archive

# 5. Eliminar todo (¡importante!)
./scripts/destroy.sh
```

---

## 🔍 ¿Qué hace cada script?

| Script              | Acción                                                                                                                                                                                  | Duración              | Indicadores clave                                                            |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ---------------------------------------------------------------------------- |
| `deploy.sh`         | • Crea Resource Group <br>• Crea Storage Account TLS 1.2, Standard\_LRS <br>• Añade contenedores `hot/`, `cool/`, `archive/` <br>• Política *Lifecycle* (prefijos `cool/` y `archive/`) | \~ 30 s               | Muestra log con timestamps y termina con `✅`                                 |
| `test-lifecycle.sh` | • Genera `sample.txt` <br>• Sube a los 3 contenedores <br>• Cambia tiers (Cool, Archive) <br>• Descarga desde Cool (OK) <br>• Descarga desde Archive (falla controlada)                 | \~ 20 s               | Crea `sample-cool-downloaded.txt`, imprime contenido; advierte sobre Archive |
| `destroy.sh`        | • Lanza borrado del RG <br>• Espera con `az group wait --deleted`                                                                                                                       | según Azure (10–60 s) | `✅ Todos los recursos se han eliminado.`                                     |
