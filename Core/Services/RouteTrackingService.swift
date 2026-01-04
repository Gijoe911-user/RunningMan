//
//  RouteTrackingService.swift
//  RunningMan
//
//  Service pour enregistrer et sauvegarder les tracés GPS
//

import Foundation
import CoreLocation
import FirebaseFirestore

/// Service de gestion des tracés GPS de sessions
class RouteTrackingService {
    
    static let shared = RouteTrackingService()
    
    private var db: Firestore {
        Firestore.firestore()
    }
    
    // Tracé en cours (en mémoire)
    private var currentRoutePoints: [CLLocationCoordinate2D] = []
    // Horodatages correspondants (même index que currentRoutePoints)
    private var currentRouteTimestamps: [Date] = []
    
    // Timer pour sauvegarde automatique
    private var autoSaveTimer: Timer?
    private var currentSessionId: String?
    private var currentUserId: String?
    
    private init() {}
    
    // MARK: - Record Route Points
    
    /// Ajoute un point au tracé en cours
    func addRoutePoint(_ coordinate: CLLocationCoordinate2D) {
        currentRoutePoints.append(coordinate)
        currentRouteTimestamps.append(Date()) // Timestamp au moment de la réception de la position
        Logger.log("[AUDIT-RTS-01] 📍 RouteTrackingService.addRoutePoint - total: \(currentRoutePoints.count)", category: .location)
    }
    
    /// Obtient le tracé en cours
    func getCurrentRoute() -> [CLLocationCoordinate2D] {
        Logger.log("[AUDIT-RTS-02] 📋 RouteTrackingService.getCurrentRoute - count: \(currentRoutePoints.count)", category: .location)
        return currentRoutePoints
    }
    
    /// Réinitialise le tracé
    func clearRoute() {
        currentRoutePoints.removeAll()
        currentRouteTimestamps.removeAll()
        Logger.log("[AUDIT-RTS-03] 🗑️ RouteTrackingService.clearRoute appelé", category: .location)
    }
    
    /// Pré-remplit les listes en mémoire avec un tracé existant SANS écraser ce qui arrive ensuite
    /// 🎯 Cette méthode permet d'éviter le "saut visuel" en chargeant d'abord l'historique
    /// avant de commencer le tracking live
    func seedRoute(_ points: [CLLocationCoordinate2D], timestamps: [Date]) {
        // Sécurité : Ne seed que si les listes sont vides (pas de tracking en cours)
        guard currentRoutePoints.isEmpty else {
            Logger.log("[AUDIT-RTS-SEED] ⚠️ seedRoute ignoré : tracking déjà en cours (\(currentRoutePoints.count) points)", category: .location)
            return
        }
        
        // Vérifier la cohérence des données
        let count = min(points.count, timestamps.count)
        guard count > 0 else {
            Logger.log("[AUDIT-RTS-SEED] ⚠️ seedRoute : aucun point à seeder", category: .location)
            return
        }
        
        // Pré-remplir les listes
        currentRoutePoints = Array(points.prefix(count))
        currentRouteTimestamps = Array(timestamps.prefix(count))
        
        Logger.logSuccess("[AUDIT-RTS-SEED] ✅ Route seedée avec \(count) points historiques", category: .location)
    }
    
    // MARK: - Auto-Save
    
    /// Démarre la sauvegarde automatique du tracé toutes les 3 minutes (180 secondes)
    /// 🎯 Sauvegarde régulière pour éviter la perte de données en cas de crash ou batterie faible
    func startAutoSave(sessionId: String, userId: String) {
        currentSessionId = sessionId
        currentUserId = userId
        
        // Annuler le timer précédent si existant
        stopAutoSave()
        
        // Créer un nouveau timer (toutes les 3 minutes = 180 secondes)
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: true) { [weak self] _ in
            Task {
                await self?.autoSaveRoute()
            }
        }
        
        Logger.log("🔄 Auto-sauvegarde activée (toutes les 3 minutes)", category: .location)
    }
    
    /// Arrête la sauvegarde automatique
    func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        Logger.log("⏸️ Auto-sauvegarde désactivée", category: .location)
    }
    
    /// Sauvegarde automatique silencieuse
    private func autoSaveRoute() async {
        guard let sessionId = currentSessionId,
              let userId = currentUserId,
              !currentRoutePoints.isEmpty else {
            return
        }
        
        do {
            try await saveRoute(sessionId: sessionId, userId: userId)
            Logger.log("💾 Auto-sauvegarde réussie (\(currentRoutePoints.count) points)", category: .location)
        } catch {
            Logger.logError(error, context: "autoSaveRoute", category: .location)
        }
    }
    
    // MARK: - Save Route to Firestore
    
    /// Sauvegarde le tracé dans Firestore
    func saveRoute(sessionId: String, userId: String) async throws {
        guard !currentRoutePoints.isEmpty else {
            Logger.log("⚠️ Aucun point à sauvegarder", category: .location)
            return
        }
        
        Logger.log("[AUDIT-RTS-04] 💾 RouteTrackingService.saveRoute - points: \(currentRoutePoints.count)", category: .location)
        
        // Convertir les coordonnées en GeoPoints
        let geoPoints = currentRoutePoints.map { coord in
            GeoPoint(latitude: coord.latitude, longitude: coord.longitude)
        }
        
        // Construire les timestamps Firestore correspondants
        // Si pour une raison quelconque les tailles diffèrent, on tronque à la taille minimale
        let count = min(geoPoints.count, currentRouteTimestamps.count)
        let safeGeoPoints = Array(geoPoints.prefix(count))
        let safeTimestamps = Array(currentRouteTimestamps.prefix(count)).map { Timestamp(date: $0) }
        
        // Créer un document de tracé enrichi
        var routeData: [String: Any] = [
            "sessionId": sessionId,
            "userId": userId,
            "points": safeGeoPoints,
            "pointsTimestamps": safeTimestamps,
            "pointsCount": count,
            "version": 2, // 🆕 Schéma v2 avec timestamps
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Sauvegarder dans Firestore
        try await db.collection("routes")
            .document("\(sessionId)_\(userId)")
            .setData(routeData)
        
        Logger.logSuccess("✅ Tracé sauvegardé: \(count) points", category: .location)
    }
    
    // MARK: - Load Route from Firestore
    
    /// Charge un tracé depuis Firestore (coordonnées seulement, sans timestamps)
    func loadRoute(sessionId: String, userId: String) async throws -> [CLLocationCoordinate2D] {
        Logger.log("[AUDIT-RTS-05] 📥 RouteTrackingService.loadRoute - sessionId: \(sessionId)", category: .location)
        
        let doc = try await db.collection("routes")
            .document("\(sessionId)_\(userId)")
            .getDocument()
        
        guard let data = doc.data(),
              let geoPoints = data["points"] as? [GeoPoint] else {
            Logger.log("⚠️ Aucun tracé trouvé", category: .location)
            return []
        }
        
        let coordinates = geoPoints.map { geoPoint in
            CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
        
        Logger.logSuccess("✅ Tracé chargé: \(coordinates.count) points", category: .location)
        return coordinates
    }
    
    /// Charge un tracé depuis Firestore avec ses timestamps pour le seeding
    func loadRouteWithTimestamps(sessionId: String, userId: String) async throws -> (coordinates: [CLLocationCoordinate2D], timestamps: [Date]) {
        Logger.log("[AUDIT-RTS-06] 📥 RouteTrackingService.loadRouteWithTimestamps - sessionId: \(sessionId)", category: .location)
        
        let doc = try await db.collection("routes")
            .document("\(sessionId)_\(userId)")
            .getDocument()
        
        guard let data = doc.data(),
              let geoPoints = data["points"] as? [GeoPoint] else {
            Logger.log("⚠️ Aucun tracé trouvé", category: .location)
            return ([], [])
        }
        
        let coordinates = geoPoints.map { geoPoint in
            CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
        }
        
        // Essayer de récupérer les timestamps (version 2)
        var timestamps: [Date] = []
        if let firestoreTimestamps = data["pointsTimestamps"] as? [Timestamp] {
            timestamps = firestoreTimestamps.map { $0.dateValue() }
        }
        
        // Si pas de timestamps ou taille différente, créer des timestamps artificiels espacés de 3 secondes
        if timestamps.isEmpty || timestamps.count != coordinates.count {
            Logger.log("⚠️ Timestamps manquants ou incohérents, génération artificielle", category: .location)
            let baseDate = Date().addingTimeInterval(-Double(coordinates.count) * 3.0)
            timestamps = (0..<coordinates.count).map { index in
                baseDate.addingTimeInterval(Double(index) * 3.0)
            }
        }
        
        Logger.logSuccess("✅ Tracé chargé avec timestamps: \(coordinates.count) points", category: .location)
        return (coordinates, timestamps)
    }
    
    /// Charge tous les tracés d'une session (tous les participants)
    func loadAllRoutes(sessionId: String) async throws -> [String: [CLLocationCoordinate2D]] {
        Logger.log("📥 Chargement de tous les tracés de la session...", category: .location)
        
        let query = db.collection("routes")
            .whereField("sessionId", isEqualTo: sessionId)
        
        let snapshot = try await query.getDocuments()
        
        var routes: [String: [CLLocationCoordinate2D]] = [:]
        
        for doc in snapshot.documents {
            let data = doc.data()
            
            guard let userId = data["userId"] as? String,
                  let geoPoints = data["points"] as? [GeoPoint] else {
                continue
            }
            
            let coordinates = geoPoints.map { geoPoint in
                CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)
            }
            
            routes[userId] = coordinates
        }
        
        Logger.logSuccess("✅ \(routes.count) tracés chargés", category: .location)
        return routes
    }
    
    // MARK: - Export GPX (Bonus)
    
    /// Génère un fichier GPX du tracé
    func generateGPX(route: [CLLocationCoordinate2D], sessionName: String) -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="RunningMan">
          <metadata>
            <name>\(sessionName)</name>
            <time>\(ISO8601DateFormatter().string(from: Date()))</time>
          </metadata>
          <trk>
            <name>\(sessionName)</name>
            <trkseg>
        """
        
        for point in route {
            gpx += """
            
              <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                <ele>0</ele>
              </trkpt>
            """
        }
        
        gpx += """
        
            </trkseg>
          </trk>
        </gpx>
        """
        
        return gpx
    }
    
    /// Sauvegarde le GPX localement
    func saveGPXToFile(route: [CLLocationCoordinate2D], sessionName: String) throws -> URL {
        let gpxContent = generateGPX(route: route, sessionName: sessionName)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "RunningMan_\(sessionName)_\(Date().timeIntervalSince1970).gpx"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try gpxContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        Logger.logSuccess("✅ GPX sauvegardé: \(fileURL.lastPathComponent)", category: .location)
        return fileURL
    }
}

