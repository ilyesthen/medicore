# 📊 RAPPORT TECHNIQUE COMPLET
## Connexion LAN entre PC Admin et Clients - Thaziri Application

**Date:** 7 Décembre 2025  
**Version:** 1.0.0  
**Application:** Thaziri Medical Management System

---

## 📋 TABLE DES MATIÈRES

1. [Vue d'ensemble de l'Architecture](#1-vue-densemble-de-larchitecture)
2. [Configuration du PC Admin (Serveur)](#2-configuration-du-pc-admin-serveur)
3. [Configuration des PCs Clients](#3-configuration-des-pcs-clients)
4. [Services et Ports Utilisés](#4-services-et-ports-utilisés)
5. [Auto-Discovery des Serveurs](#5-auto-discovery-des-serveurs)
6. [Communication HTTP (Base de Données)](#6-communication-http-base-de-données)
7. [Découverte Réseau des Utilisateurs](#7-découverte-réseau-des-utilisateurs)
8. [Service de Messagerie TCP](#8-service-de-messagerie-tcp)
9. [Routage des Appels Base de Données](#9-routage-des-appels-base-de-données)
10. [Sécurité et Gestion des Erreurs](#10-sécurité-et-gestion-des-erreurs)
11. [Fichiers de Configuration](#11-fichiers-de-configuration)
12. [Flux de Données Complet](#12-flux-de-données-complet)
13. [Résumé Technique](#13-résumé-technique)

---

## 1. Vue d'ensemble de l'Architecture

### Architecture Réseau

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RÉSEAU LOCAL (LAN)                                │
│                                                                             │
│  ┌──────────────────────────────────────┐                                   │
│  │         PC ADMIN (SERVEUR)           │                                   │
│  │                                      │                                   │
│  │  ┌────────────────────────────────┐  │                                   │
│  │  │   SQLite Database (Prisma)     │  │                                   │
│  │  │   thaziri-database.db          │  │                                   │
│  │  └────────────────────────────────┘  │                                   │
│  │              ▲                       │                                   │
│  │              │                       │                                   │
│  │  ┌────────────────────────────────┐  │                                   │
│  │  │   DatabaseServer (Express)     │◄─────────────── Port 3456 (HTTP)    │
│  │  │   Écoute sur 0.0.0.0:3456      │  │                                   │
│  │  └────────────────────────────────┘  │                                   │
│  │                                      │                                   │
│  │  ┌────────────────────────────────┐  │                                   │
│  │  │   ServerDiscovery (UDP)        │◄─────────────── Port 3457 (UDP)     │
│  │  │   Répond aux découvertes       │  │                                   │
│  │  └────────────────────────────────┘  │                                   │
│  │                                      │                                   │
│  │  ┌────────────────────────────────┐  │                                   │
│  │  │   NetworkDiscoveryService      │◄─────────────── Port 45678 (UDP)    │
│  │  │   Broadcast présence           │  │                                   │
│  │  └────────────────────────────────┘  │                                   │
│  │                                      │                                   │
│  │  ┌────────────────────────────────┐  │                                   │
│  │  │   MessagingService (TCP)       │◄─────────────── Port 45679 (TCP)    │
│  │  │   Messages directs             │  │                                   │
│  │  └────────────────────────────────┘  │                                   │
│  │                                      │                                   │
│  └──────────────────────────────────────┘                                   │
│                     │                                                        │
│                     │ HTTP/UDP/TCP                                          │
│                     ▼                                                        │
│  ┌──────────────────────────────────────┐  ┌─────────────────────────────┐  │
│  │         PC CLIENT 1                  │  │      PC CLIENT 2            │  │
│  │                                      │  │                             │  │
│  │  ┌────────────────────────────────┐  │  │  ┌───────────────────────┐  │  │
│  │  │   DatabaseClient (Axios)       │  │  │  │   DatabaseClient      │  │  │
│  │  │   Appels HTTP vers Admin       │  │  │  │   HTTP vers Admin     │  │  │
│  │  └────────────────────────────────┘  │  │  └───────────────────────┘  │  │
│  │                                      │  │                             │  │
│  │  ┌────────────────────────────────┐  │  │  ┌───────────────────────┐  │  │
│  │  │   NetworkDiscoveryService      │  │  │  │   NetworkDiscovery    │  │  │
│  │  │   Port 45678 (UDP)             │  │  │  │   Port 45678          │  │  │
│  │  └────────────────────────────────┘  │  │  └───────────────────────┘  │  │
│  │                                      │  │                             │  │
│  │  ┌────────────────────────────────┐  │  │  ┌───────────────────────┐  │  │
│  │  │   MessagingService (TCP)       │  │  │  │   MessagingService    │  │  │
│  │  │   Port 45679                   │  │  │  │   Port 45679          │  │  │
│  │  └────────────────────────────────┘  │  │  └───────────────────────┘  │  │
│  │                                      │  │                             │  │
│  └──────────────────────────────────────┘  └─────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Mode de Fonctionnement Dual

L'application fonctionne en **deux modes distincts** :

| Mode | Description | Base de données |
|------|-------------|-----------------|
| **ADMIN** | PC principal avec la base de données locale | SQLite via Prisma (accès direct) |
| **CLIENT** | PCs secondaires connectés au réseau | HTTP vers PC Admin |

---

## 2. Configuration du PC Admin (Serveur)

### 2.1 Fichier Source Principal
**Fichier:** `src/main/services/DatabaseServer.ts`

### 2.2 Initialisation du Serveur

```typescript
// Classe DatabaseServer - Serveur Express professionnel
export class DatabaseServer {
  private app: express.Application
  private server: Server | null = null
  private prisma: PrismaClient
  private port: number = 3456  // PORT FIXE POUR LA DÉCOUVERTE
  private isRunning: boolean = false

  constructor(prisma: PrismaClient) {
    this.prisma = prisma
    this.app = express()
    
    // Activation CORS pour tous les PCs clients
    this.app.use(cors())
    this.app.use(express.json({ limit: '50mb' }))
    
    this.setupRoutes()
  }
}
```

### 2.3 Démarrage Automatique (Auto-Start)

**Fichier:** `src/main/index.ts` (lignes 146-175)

```typescript
// AUTO-START SERVER EN MODE ADMIN
const mode = await dbRouter.getMode()
if (mode === 'admin') {
  console.log('🚀 Admin mode detected - Auto-starting database server...')
  
  const prismaClient = db.getPrismaClient()
  databaseServer = new DatabaseServer(prismaClient)
  const result = await databaseServer.start()
  
  if (result.success) {
    console.log(`✅ Database server auto-started:`)
    console.log(`   IP: ${result.ip}`)
    console.log(`   Port: ${result.port}`)
    console.log(`   URL: http://${result.ip}:${result.port}`)
    
    // Démarrer le répondeur de découverte
    serverDiscovery = new ServerDiscovery()
    const computerName = require('os').hostname()
    await serverDiscovery.startBroadcastResponder(result.port!, computerName)
  }
}
```

### 2.4 Binding sur Toutes les Interfaces

```typescript
async start(): Promise<{ success: boolean; port?: number; ip?: string; error?: string }> {
  return new Promise((resolve) => {
    // Écoute sur 0.0.0.0 = toutes les interfaces réseau
    this.server = this.app.listen(this.port, '0.0.0.0', () => {
      this.isRunning = true
      
      // Obtenir l'IP locale
      const networkInterfaces = os.networkInterfaces()
      let localIP = 'localhost'
      
      for (const netInterface of Object.values(networkInterfaces)) {
        for (const addr of netInterface || []) {
          if (addr.family === 'IPv4' && !addr.internal) {
            localIP = addr.address
            break
          }
        }
      }
      
      console.log(`✅ Database Server started on http://${localIP}:${this.port}`)
      resolve({ success: true, port: this.port, ip: localIP })
    })
  })
}
```

### 2.5 Partage Réseau Windows (Automatique)

**Fichier:** `src/main/index.ts` (lignes 1702-1740)

```typescript
// PowerShell pour créer le partage automatiquement
if (process.platform === 'win32') {
  const psCommand = `
    $shareName = "${shareName}"
    $folderPath = "${userDataPath.replace(/\\/g, '\\\\')}"
    
    # Vérifier si le partage existe
    $existingShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue
    
    if ($existingShare) {
      Set-SmbShare -Name $shareName -Path $folderPath -FullAccess "Everyone"
    } else {
      New-SmbShare -Name $shareName -Path $folderPath -FullAccess "Everyone" -Description "Thaziri Database Share"
    }
  `
  
  execSync(`powershell.exe -Command "${psCommand}"`)
}
```

---

## 3. Configuration des PCs Clients

### 3.1 Fichier Source Principal
**Fichier:** `src/main/services/DatabaseClient.ts`

### 3.2 Client HTTP avec Axios

```typescript
export class DatabaseClient {
  private client: AxiosInstance
  private serverUrl: string
  private isConnected: boolean = false

  constructor(serverUrl: string) {
    this.serverUrl = serverUrl
    this.client = axios.create({
      baseURL: serverUrl,
      timeout: 10000,  // 10 secondes de timeout
      headers: {
        'Content-Type': 'application/json'
      }
    })
  }
}
```

### 3.3 Test de Connexion

```typescript
async testConnection(): Promise<{ success: boolean; serverInfo?: any; error?: string }> {
  try {
    const response = await this.client.get('/health')
    if (response.data.status === 'ok') {
      this.isConnected = true
      return { success: true, serverInfo: response.data }
    }
    return { success: false, error: 'Invalid server response' }
  } catch (error: any) {
    this.isConnected = false
    if (error.code === 'ECONNREFUSED') {
      return { 
        success: false, 
        error: `Impossible de se connecter au serveur.

Vérifiez que:
1. Le PC Admin est allumé
2. L'application Thaziri est ouverte sur le PC Admin
3. Les deux PCs sont sur le même réseau` 
      }
    }
    return { success: false, error: error.message || 'Connection failed' }
  }
}
```

### 3.4 Exécution des Fonctions Base de Données

```typescript
async executeDatabaseFunction(functionName: string, ...args: any[]): Promise<any> {
  console.log(`📡 CLIENT HTTP REQUEST: /db/execute`)
  console.log(`   Function: ${functionName}`)
  console.log(`   Args:`, args)
  
  const response = await this.client.post('/db/execute', {
    functionName,
    args
  })
  
  console.log(`✅ CLIENT HTTP RESPONSE:`)
  console.log(`   Status: ${response.status}`)
  console.log(`   Data:`, response.data)
  
  return response.data
}
```

---

## 4. Services et Ports Utilisés

### 4.1 Tableau Récapitulatif des Ports

| Port | Protocole | Service | Description | Utilisé par |
|------|-----------|---------|-------------|-------------|
| **3456** | HTTP/TCP | DatabaseServer | API REST pour accès base de données | Admin (écoute), Clients (connect) |
| **3457** | UDP | ServerDiscovery | Découverte automatique du serveur | Admin (écoute), Clients (broadcast) |
| **45678** | UDP | NetworkDiscoveryService | Découverte des utilisateurs en ligne | Tous les PCs |
| **45679** | TCP | MessagingService | Messagerie directe entre utilisateurs | Tous les PCs |

### 4.2 Détail du Port 3456 (DatabaseServer)

**Endpoints disponibles :**

| Endpoint | Méthode | Description |
|----------|---------|-------------|
| `/health` | GET | Vérification de l'état du serveur |
| `/info` | GET | Informations du serveur (IP, hostname, uptime) |
| `/query` | POST | Exécution de requêtes Prisma génériques |
| `/db/execute` | POST | Exécution de fonctions database par nom |
| `/patients` | GET | Liste des 100 derniers patients |
| `/patients/search/:term` | GET | Recherche de patients |
| `/api/medicines` | GET | Liste des médicaments |
| `/api/quantities` | GET | Liste des quantités |
| `/api/comptesRendus` | GET | Liste des comptes rendus |
| `/api/ordonnances/:patientCode` | GET | Ordonnances d'un patient |
| `/api/ordonnances` | POST | Créer une ordonnance |
| `/api/ordonnances/:id` | PUT | Modifier une ordonnance |
| `/api/ordonnances/:id` | DELETE | Supprimer une ordonnance |

### 4.3 Détail du Port 3457 (ServerDiscovery)

```typescript
const DISCOVERY_PORT = 3457
const DISCOVERY_MESSAGE = 'THAZIRI_DISCOVER'
const DISCOVERY_RESPONSE = 'THAZIRI_SERVER'
```

**Protocole de découverte :**
1. Client envoie `THAZIRI_DISCOVER` en broadcast UDP
2. Admin répond avec JSON contenant IP, port, et nom d'ordinateur
3. Client affiche les serveurs découverts

### 4.4 Détail du Port 45678 (NetworkDiscoveryService)

```typescript
private readonly BROADCAST_PORT = 45678
private readonly BROADCAST_INTERVAL = 5000   // 5 secondes
private readonly STALE_TIMEOUT = 15000       // 15 secondes
private readonly CLEANUP_INTERVAL = 3000     // 3 secondes
```

**Structure du paquet broadcast :**

```typescript
interface BroadcastPacket {
  userId: number
  username: string
  role: string
  messagingPort: number
  type: 'presence' | 'goodbye'
}
```

### 4.5 Détail du Port 45679 (MessagingService)

```typescript
private port: number = 45679
```

**Structure des messages :**

```typescript
interface Message {
  senderId: string
  senderName: string
  senderRole?: string
  content: string
  timestamp: number
  audioData?: string      // Base64 pour messages vocaux
  isVoiceMessage?: boolean
  roomId?: number
  recipientId?: string
  patientContext?: {
    patientName?: string
    patientId?: string
  }
}
```

---

## 5. Auto-Discovery des Serveurs

### 5.1 Fichier Source
**Fichier:** `src/main/services/ServerDiscovery.ts`

### 5.2 Côté Admin : Répondeur de Découverte

```typescript
async startBroadcastResponder(serverPort: number, computerName: string): Promise<void> {
  this.socket = dgram.createSocket('udp4')

  this.socket.on('message', (msg, rinfo) => {
    const message = msg.toString()
    
    if (message === DISCOVERY_MESSAGE) {
      console.log(`📡 Discovery request from ${rinfo.address}`)
      
      // Répondre avec les infos du serveur
      const response = JSON.stringify({
        type: DISCOVERY_RESPONSE,
        computerName,
        ip: this.getLocalIP(),
        port: serverPort,
        timestamp: Date.now()
      })
      
      this.socket!.send(response, rinfo.port, rinfo.address)
      console.log(`✅ Sent discovery response to ${rinfo.address}`)
    }
  })

  this.socket.bind(DISCOVERY_PORT)  // Port 3457
}
```

### 5.3 Côté Client : Découverte des Serveurs

```typescript
async discoverServers(timeoutMs: number = 3000): Promise<Array<{ ip: string; port: number; computerName: string }>> {
  return new Promise((resolve, reject) => {
    const socket = dgram.createSocket('udp4')

    socket.on('message', (msg, rinfo) => {
      const data = JSON.parse(msg.toString())
      
      if (data.type === DISCOVERY_RESPONSE) {
        console.log(`✅ Found server: ${data.computerName} at ${data.ip}:${data.port}`)
        
        this.discoveredServers.set(data.ip, {
          ip: data.ip,
          port: data.port,
          computerName: data.computerName
        })
      }
    })

    socket.bind(() => {
      socket.setBroadcast(true)
      
      // Envoyer broadcast vers 255.255.255.255
      const message = Buffer.from(DISCOVERY_MESSAGE)
      socket.send(message, DISCOVERY_PORT, '255.255.255.255')

      // Timeout après 3 secondes
      setTimeout(() => {
        socket.close()
        resolve(Array.from(this.discoveredServers.values()))
      }, timeoutMs)
    })
  })
}
```

### 5.4 IPC Handler pour la Découverte

**Fichier:** `src/main/index.ts` (lignes 2013-2040)

```typescript
ipcMain.handle('server:discover', async () => {
  console.log('📡 Starting server discovery...')
  
  const discovery = new ServerDiscovery()
  const servers = await discovery.discoverServers(3000)  // 3 secondes timeout
  discovery.stop()
  
  console.log(`📡 Found ${servers.length} server(s)`)
  
  return {
    success: true,
    servers: servers.map(s => ({
      ip: s.ip,
      port: s.port,
      computerName: s.computerName,
      url: `http://${s.ip}:${s.port}`
    }))
  }
})
```

---

## 6. Communication HTTP (Base de Données)

### 6.1 Endpoint Principal : `/db/execute`

**Fichier:** `src/main/services/DatabaseServer.ts` (lignes 126-170)

```typescript
this.app.post('/db/execute', async (req, res) => {
  try {
    const { functionName, args } = req.body
    
    console.log(`📡 SERVER RECEIVED: /db/execute`)
    console.log(`   Function: ${functionName}`)
    console.log(`   Args:`, args)
    
    if (!functionName) {
      return res.status(400).json({ error: 'Missing functionName' })
    }
    
    // Récupérer la fonction depuis le module database
    const func = (db as any)[functionName]
    
    if (!func || typeof func !== 'function') {
      return res.status(400).json({ error: `Function ${functionName} not found` })
    }
    
    // Appeler la fonction avec les arguments
    const result = await func(...(args || []))
    
    res.json({ success: true, data: result })
  } catch (error: any) {
    res.status(500).json({ 
      success: false, 
      error: error.message,
      details: error.toString()
    })
  }
})
```

### 6.2 Health Check Endpoint

```typescript
this.app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Thaziri Database Server',
    version: '1.0.0',
    computerName: os.hostname()
  })
})
```

### 6.3 Server Info Endpoint

```typescript
this.app.get('/info', (req, res) => {
  const networkInterfaces = os.networkInterfaces()
  const addresses: string[] = []
  
  Object.values(networkInterfaces).forEach(netInterface => {
    netInterface?.forEach(addr => {
      if (addr.family === 'IPv4' && !addr.internal) {
        addresses.push(addr.address)
      }
    })
  })
  
  res.json({
    computerName: os.hostname(),
    ipAddresses: addresses,
    port: this.port,
    platform: os.platform(),
    uptime: process.uptime()
  })
})
```

---

## 7. Découverte Réseau des Utilisateurs

### 7.1 Fichier Source
**Fichier:** `src/main/services/NetworkDiscoveryService.ts`

### 7.2 Structure des Utilisateurs Réseau

```typescript
export interface NetworkUser {
  userId: number
  username: string
  role: string
  ipAddress: string
  messagingPort: number
  lastSeen: number
}
```

### 7.3 Calcul de l'Adresse Broadcast

```typescript
private getBroadcastAddress(): string {
  const interfaces = os.networkInterfaces()
  
  for (const name of Object.keys(interfaces)) {
    const netInterface = interfaces[name]
    if (!netInterface) continue

    for (const iface of netInterface) {
      if (iface.family === 'IPv4' && !iface.internal) {
        // Calculer l'adresse broadcast
        const ip = iface.address.split('.').map(Number)
        const netmask = iface.netmask.split('.').map(Number)
        const broadcast = ip.map((octet, i) => octet | (~netmask[i] & 255))
        return broadcast.join('.')
      }
    }
  }

  // Fallback
  return '255.255.255.255'
}
```

### 7.4 Gestion des Utilisateurs Actifs

```typescript
// Mise à jour d'un utilisateur
private updateUser(user: NetworkUser): void {
  const wasPresent = this.activeUsers.has(user.userId)
  this.activeUsers.set(user.userId, user)

  if (!wasPresent) {
    console.log(`[NetworkDiscovery] New user detected: ${user.username} (${user.role}) - ${user.ipAddress}`)
  }

  this.emitUsersUpdate()
}

// Nettoyage des utilisateurs inactifs
private removeStaleUsers(): void {
  const now = Date.now()

  for (const [userId, user] of this.activeUsers.entries()) {
    if (now - user.lastSeen > this.STALE_TIMEOUT) {  // 15 secondes
      console.log(`[NetworkDiscovery] Removing stale user: ${user.username}`)
      this.activeUsers.delete(userId)
    }
  }
}
```

### 7.5 Interface UI Utilisateurs en Ligne

**Fichier:** `src/renderer/src/components/NetworkUserList.tsx`

```typescript
const NetworkUserList: React.FC = () => {
  const [activeUsers, setActiveUsers] = useState<NetworkUser[]>([])

  useEffect(() => {
    const networkAPI = getNetworkAPI()
    
    // Récupérer la liste initiale
    networkAPI.getActiveUsers()?.then((users: NetworkUser[]) => {
      setActiveUsers(users)
    })

    // Écouter les mises à jour en temps réel
    const cleanup = networkAPI.onUsersUpdate((users: NetworkUser[]) => {
      setActiveUsers(users)
    })

    return cleanup
  }, [])
}
```

---

## 8. Service de Messagerie TCP

### 8.1 Fichier Source
**Fichier:** `src/main/services/MessagingService.ts`

### 8.2 Serveur TCP

```typescript
public async startServer(): Promise<void> {
  return new Promise((resolve, reject) => {
    this.server = net.createServer((socket) => {
      console.log('📨 New incoming connection:', socket.remoteAddress)
      
      // Initialiser le buffer pour ce socket
      this.messageBuffer.set(socket, Buffer.alloc(0))

      socket.on('data', (data) => {
        this.handleIncomingData(socket, data)
      })

      socket.on('error', (error) => {
        console.error('❌ Socket error:', error)
        this.messageBuffer.delete(socket)
      })

      socket.on('close', () => {
        console.log('🔌 Connection closed:', socket.remoteAddress)
        this.messageBuffer.delete(socket)
      })
    })

    this.server.listen(this.port, () => {
      console.log(`📬 Messaging server listening on port ${this.port}`)
      resolve()
    })
  })
}
```

### 8.3 Protocole de Framing (Length-Prefix)

```typescript
// Lecture avec préfixe de longueur
private async processBuffer(socket: net.Socket): Promise<void> {
  const buffer = this.messageBuffer.get(socket)
  if (!buffer || buffer.length < 4) {
    return  // Pas assez de données pour le préfixe de longueur
  }

  // Lire le préfixe de 4 octets
  const messageLength = buffer.readUInt32BE(0)

  // Vérifier si le message complet est arrivé
  if (buffer.length < 4 + messageLength) {
    return  // Message incomplet, attendre plus de données
  }

  // Extraire le message complet
  const messageBuffer = buffer.slice(4, 4 + messageLength)
  const messageJson = messageBuffer.toString('utf-8')
  const message = JSON.parse(messageJson) as Message
  
  // Traiter le message...
}
```

### 8.4 Envoi de Messages Directs

```typescript
private async sendDirectMessage(params: SendMessageParams): Promise<void> {
  const { recipientIp, recipientPort, content, senderId, senderName } = params

  return new Promise((resolve, reject) => {
    const message: Message = {
      senderId,
      senderName,
      content,
      timestamp: Date.now()
    }

    const messageJson = JSON.stringify(message)
    const messageBuffer = Buffer.from(messageJson, 'utf-8')
    
    // Créer le préfixe de longueur (4 octets, Big Endian)
    const lengthPrefix = Buffer.alloc(4)
    lengthPrefix.writeUInt32BE(messageBuffer.length, 0)

    // Créer la connexion TCP
    const client = net.createConnection({
      host: recipientIp,
      port: recipientPort,
      timeout: 5000
    }, () => {
      console.log(`📤 Connected to ${recipientIp}:${recipientPort}`)
      
      // Envoyer le message avec préfixe
      client.write(lengthPrefix)
      client.write(messageBuffer)
      
      client.end()
      resolve()
    })

    client.on('error', reject)
    client.on('timeout', () => {
      client.destroy()
      reject(new Error('Connection timeout'))
    })
  })
}
```

### 8.5 Broadcast vers une Salle

```typescript
private async broadcastRoomMessage(params: SendMessageParams): Promise<void> {
  const networkService = NetworkDiscoveryService.getInstance()
  const activeUsers = networkService.getActiveUsers()

  // Envoyer à tous les utilisateurs actifs (sauf soi-même)
  const sendPromises = activeUsers
    .filter(user => user.userId.toString() !== params.senderId)
    .map(user => {
      return this.sendDirectMessage({
        recipientIp: user.ipAddress,
        recipientPort: user.messagingPort,
        ...params
      })
    })

  await Promise.all(sendPromises)
  console.log(`📢 Broadcasted message to room ${params.roomId} (${sendPromises.length} recipients)`)
}
```

---

## 9. Routage des Appels Base de Données

### 9.1 Fichier Source
**Fichier:** `src/main/services/DatabaseRouter.ts`

### 9.2 Détection du Mode

```typescript
async function detectMode(): Promise<DatabaseMode> {
  const userDataPath = app.getPath('userData')
  const setupCompletePath = path.join(userDataPath, 'setup-complete')
  
  if (!fs.existsSync(setupCompletePath)) {
    return null  // Setup non complété
  }
  
  const setupData = JSON.parse(fs.readFileSync(setupCompletePath, 'utf-8'))
  return setupData.mode || 'admin'
}
```

### 9.3 Fonction de Routage Principale

```typescript
async function executeDbFunction(functionName: string, ...args: any[]): Promise<any> {
  console.log(`🔀 DB FUNCTION CALL: ${functionName}`)
  console.log(`   Mode: ${currentMode}`)
  console.log(`   Has databaseClient: ${databaseClient !== null}`)
  
  // MODE CLIENT : Utiliser HTTP
  if (currentMode === 'client') {
    if (!databaseClient) {
      throw new Error(`CLIENT MODE ERROR: Database client not initialized. Please connect to the admin server first.`)
    }
    
    // Appel HTTP vers le serveur admin
    const result = await databaseClient.executeDatabaseFunction(functionName, ...args)
    
    if (result.success) {
      return result.data
    }
    throw new Error(result.error || 'Database function failed')
  }
  
  // MODE ADMIN : Appel direct Prisma
  const func = (db as any)[functionName]
  
  if (!func) {
    throw new Error(`Function ${functionName} not found in database module`)
  }
  
  return await func(...args)
}
```

### 9.4 Fonctions Exportées (Exemples)

```typescript
// Opérations Patients
export async function getAllPatients(limit?: number, offset?: number): Promise<any[]> {
  return await executeDbFunction('getAllPatients', limit, offset)
}

export async function createPatient(data: any): Promise<any> {
  return await executeDbFunction('createPatient', data)
}

// Opérations Visites
export const createVisit = (data: any) => executeDbFunction('createVisit', data)
export const getAllVisitsByPatient = (patientCode: number) => executeDbFunction('getAllVisitsByPatient', patientCode)

// Opérations Paiements
export const createPaymentValidation = (data: any) => executeDbFunction('createPaymentValidation', data)

// Et plus de 60 autres fonctions...
```

---

## 10. Sécurité et Gestion des Erreurs

### 10.1 CORS Configuration

```typescript
// Activation CORS pour tous les clients
this.app.use(cors())
```

### 10.2 Limite de Taille des Requêtes

```typescript
this.app.use(express.json({ limit: '50mb' }))
```

### 10.3 Timeout des Connexions Client

```typescript
this.client = axios.create({
  baseURL: serverUrl,
  timeout: 10000,  // 10 secondes
})
```

### 10.4 Gestion des Erreurs de Connexion

```typescript
if (error.code === 'ECONNREFUSED') {
  return { 
    success: false, 
    error: `Impossible de se connecter au serveur.

Vérifiez que:
1. Le PC Admin est allumé
2. L'application Thaziri est ouverte sur le PC Admin
3. Les deux PCs sont sur le même réseau` 
  }
}
```

### 10.5 Logs Détaillés

```typescript
console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`)
console.log(`🔀 DB FUNCTION CALL: ${functionName}`)
console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`)
console.log(`📊 CURRENT STATE:`)
console.log(`   Mode: ${currentMode}`)
console.log(`   Has databaseClient: ${databaseClient !== null}`)
console.log(`   Arguments:`, args)
```

---

## 11. Fichiers de Configuration

### 11.1 Fichier `setup-complete`

**Chemin:** `{userData}/setup-complete`

```json
// MODE ADMIN
{
  "mode": "admin",
  "completedAt": "2025-12-07T12:00:00.000Z",
  "shareName": "ThaziriDB",
  "computerName": "ADMIN-PC",
  "uncPath": "\\\\ADMIN-PC\\ThaziriDB\\thaziri-database.db",
  "databasePath": "/path/to/thaziri-database.db",
  "shareCreated": true
}

// MODE CLIENT
{
  "mode": "client",
  "completedAt": "2025-12-07T12:05:00.000Z",
  "serverUrl": "http://192.168.1.100:3456"
}
```

### 11.2 Fichier `database-config.json`

**Chemin:** `{userData}/database-config.json`

```json
{
  "serverUrl": "http://192.168.1.100:3456"
}
```

---

## 12. Flux de Données Complet

### 12.1 Scénario : Client Lit des Patients

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  React UI   │         │ IPC Handler │         │  Database   │
│   (Client)  │         │   (Main)    │         │   Router    │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       │ 1. getAllPatients()   │                       │
       ├──────────────────────►│                       │
       │                       │                       │
       │                       │ 2. Check mode         │
       │                       ├──────────────────────►│
       │                       │                       │
       │                       │ 3. mode = 'client'    │
       │                       │◄──────────────────────┤
       │                       │                       │
┌──────┴──────┐         ┌──────┴──────┐         ┌──────┴──────┐
│             │         │             │         │             │
└─────────────┘         └─────────────┘         └──────┬──────┘
                                                       │
                                                       │ 4. HTTP POST /db/execute
                                                       │    {"functionName": "getAllPatients"}
                                                       ▼
                                                ┌─────────────┐
                                                │   Admin PC  │
                                                │   (Server)  │
                                                └──────┬──────┘
                                                       │
                                                       │ 5. Prisma query
                                                       ▼
                                                ┌─────────────┐
                                                │   SQLite    │
                                                │   Database  │
                                                └──────┬──────┘
                                                       │
                                                       │ 6. Return patients[]
                                                       ▼
                                                ┌─────────────┐
                                                │   HTTP      │
                                                │   Response  │
                                                └──────┬──────┘
                                                       │
       ┌───────────────────────────────────────────────┘
       │ 7. {success: true, data: patients[]}
       ▼
┌─────────────┐
│  React UI   │
│   Display   │
└─────────────┘
```

### 12.2 Scénario : Découverte du Serveur

```
┌─────────────┐                              ┌─────────────┐
│  Client PC  │                              │  Admin PC   │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │ 1. UDP Broadcast                           │
       │    "THAZIRI_DISCOVER"                      │
       │    → 255.255.255.255:3457                  │
       ├────────────────────────────────────────────►
       │                                            │
       │                                            │ 2. Receive broadcast
       │                                            │
       │ 3. UDP Response                            │
       │    {"type":"THAZIRI_SERVER",               │
       │     "computerName":"ADMIN-PC",             │
       │     "ip":"192.168.1.100",                  │
       │     "port":3456}                           │
       ◄────────────────────────────────────────────┤
       │                                            │
       │ 4. Display server                          │
       │    in UI dropdown                          │
       ▼                                            │
┌─────────────┐                              ┌──────┴──────┐
│ Select and  │                              │             │
│  Connect    │                              └─────────────┘
└─────────────┘
```

### 12.3 Scénario : Message Direct entre Utilisateurs

```
┌─────────────┐                              ┌─────────────┐
│   User A    │                              │   User B    │
│ (Sender)    │                              │ (Receiver)  │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │ 1. Get active users                        │
       │    from NetworkDiscoveryService            │
       │                                            │
       │ 2. TCP Connect                             │
       │    to User B IP:45679                      │
       ├────────────────────────────────────────────►
       │                                            │
       │ 3. Send length prefix (4 bytes)            │
       ├────────────────────────────────────────────►
       │                                            │
       │ 4. Send message JSON                       │
       │    {"senderId":"1",                        │
       │     "senderName":"Dr. Martin",             │
       │     "content":"Patient ready",             │
       │     "timestamp":1702123456789}             │
       ├────────────────────────────────────────────►
       │                                            │
       │ 5. Close connection                        │
       ├────────────────────────────────────────────►
       │                                            │
       │                                            │ 6. Parse message
       │                                            │    Save to DB
       │                                            │    Push to UI
       │                                            ▼
       │                                     ┌──────────────┐
       │                                     │ Notification │
       │                                     │ in React UI  │
       │                                     └──────────────┘
```

---

## 13. Résumé Technique

### 13.1 Technologies Utilisées

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Framework Desktop | Electron | Latest |
| Base de données | SQLite + Prisma | Latest |
| Serveur HTTP | Express.js | Latest |
| Client HTTP | Axios | Latest |
| Protocole découverte | UDP (dgram) | Node.js natif |
| Protocole messagerie | TCP (net) | Node.js natif |
| Interface | React + TypeScript | Latest |

### 13.2 Points Clés de l'Implémentation

1. **Architecture Dual-Mode** : L'application détecte automatiquement si elle doit fonctionner en mode Admin ou Client

2. **Découverte Automatique** : Les clients peuvent trouver le serveur admin sans configuration manuelle grâce au broadcast UDP

3. **Routage Transparent** : Le `DatabaseRouter` abstrait complètement la différence entre appels locaux et HTTP

4. **Présence Temps Réel** : Tous les utilisateurs voient qui est en ligne grâce au service de découverte réseau

5. **Messagerie Directe** : Communication peer-to-peer TCP avec protocole de framing robuste

6. **Logs Détaillés** : Traçabilité complète de tous les appels pour le débogage

### 13.3 Ports à Ouvrir dans le Pare-feu

| Port | Protocole | Direction | Description |
|------|-----------|-----------|-------------|
| 3456 | TCP | Entrant | API REST Database |
| 3457 | UDP | Entrant/Sortant | Découverte serveur |
| 45678 | UDP | Entrant/Sortant | Découverte utilisateurs |
| 45679 | TCP | Entrant/Sortant | Messagerie |

### 13.4 Fichiers Sources Principaux

| Fichier | Lignes | Rôle |
|---------|--------|------|
| `DatabaseServer.ts` | 333 | Serveur HTTP Express (Admin) |
| `DatabaseClient.ts` | 125 | Client HTTP Axios (Client) |
| `DatabaseRouter.ts` | 464 | Routage Admin/Client |
| `ServerDiscovery.ts` | 146 | Découverte UDP serveur |
| `NetworkDiscoveryService.ts` | 351 | Découverte utilisateurs |
| `MessagingService.ts` | 369 | Messagerie TCP |
| `index.ts` (main) | 2184 | Handlers IPC et init |

---

## 📝 Notes Finales

Ce système de connexion LAN a été conçu pour être :

- **Automatique** : Démarrage auto du serveur, découverte auto des serveurs
- **Transparent** : Le code métier ne sait pas s'il utilise HTTP ou Prisma direct
- **Robuste** : Gestion des erreurs, timeouts, reconnexion
- **Temps Réel** : Présence des utilisateurs et messagerie instantanée
- **Scalable** : Supporte plusieurs clients simultanés

---

*Rapport généré le 7 Décembre 2025*  
*Application Thaziri - Système de Gestion Médicale*
