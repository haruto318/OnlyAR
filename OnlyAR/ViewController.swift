//
//  ViewController.swift
//  OnlyAR
//
//  Created by Haruto Hamano on 2024/07/09.
//

//
//  ViewController.swift
//  OnlyAR
//
//  Created by Haruto Hamano on 2024/07/09.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation
import Vision

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    var pickerTitleLabel: UILabel!
    let PickerView = UIPickerView()
    let kakuninButton = UIButton()
    var roomArray: [(id: String, index: Character)] = []
    var start: Character = "H"
    var goal: Character = "H"
    
    private var resetButton: UIButton!
    private var stopButton: UIButton!

    private let configuration = ARWorldTrackingConfiguration()
    var locationService: LocationService = LocationService()
    private var sceneView: ARSCNView!
    
    private var arrowNodes: [SCNNode] = []
    var startLocation = simd_float4x4()
    
    ///Text Detection
    private var textDetectionRequest: VNRecognizeTextRequest?
    private var lastProcessingTime = Date()
    private var processInterval: TimeInterval = 5 // 1秒ごとに処理
    private var visited_room:[String] = []
    private var locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    var detectedText: (id: String, index: Character) = (id: "", index: "H") //Characterの初期値わからん
    private var isTextRecognitionRunning: Bool = false
    
    var position: SCNVector3 = SCNVector3()
    var normal: SCNVector3 = SCNVector3()
    var right: SCNVector3 = SCNVector3()
    var lastSpherePosition: SCNVector3 = SCNVector3()
    
    var isInitialDisplay: Bool = true
    
    var locations: [CLLocation] = []
    
    var orientationTimer: Timer?
    var orientationRecords: [OrientationRecord] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        roomArray = [
            (id: "H705", index: "H"),
            (id: "H706", index: "I"),
            (id: "H707", index: "J"),
            (id: "H708", index: "M"),
            (id: "H709", index: "N"),
            (id: "H723", index: "G"),
            (id: "H724", index: "F"),
            (id: "H725", index: "E"),
            (id: "H726", index: "D"),
            (id: "H727", index: "C"),
            (id: "H728", index: "B"),
            (id: "H729", index: "A")]
        
        setupSceneView()
        setupScene()
        setupLocationService()
        setupPickerView()
        setupConfirmationButton()
        setupTextDetection()
        setupResetButton()
        setupStopButton()
    }
    
    private func setupResetButton() {
        resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        self.view.addSubview(resetButton)
        
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resetButton.widthAnchor.constraint(equalToConstant: 80),
            resetButton.heightAnchor.constraint(equalToConstant: 40),
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupStopButton() {
        stopButton = UIButton(type: .system)
        stopButton.setTitle("Stop", for: .normal)
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        stopButton.layer.cornerRadius = 10
        stopButton.addTarget(self, action: #selector(stopOrientationButtonTapped), for: .touchUpInside)
        
        self.view.addSubview(stopButton)
        
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.widthAnchor.constraint(equalToConstant: 80),
            stopButton.heightAnchor.constraint(equalToConstant: 40),
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
        
    @objc private func resetButtonTapped() {
        arrowNodes.removeAll()
        restartSession()
    }
    
    @objc private func stopOrientationButtonTapped() {
        stopOrientationRecording()
        createFile()
    }
    
    func setupPickerView() {
        PickerView.delegate = self
        PickerView.dataSource = self
        view.addSubview(PickerView)
        
        PickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            PickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            PickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            PickerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            PickerView.heightAnchor.constraint(equalToConstant: 150)
        ])
        
        PickerView.layer.borderWidth = 1.0
        PickerView.layer.borderColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1.0).cgColor
    }

    func setupConfirmationButton() {
        kakuninButton.setTitle("Confirmed Start and Goal", for: .normal)
        kakuninButton.titleLabel?.font = UIFont(name: "HiraKakuProN-W6", size: 14)
        kakuninButton.setTitleColor(.white, for: .normal)
        kakuninButton.backgroundColor = UIColor(red: 0.13, green: 0.61, blue: 0.93, alpha: 1.0)
        kakuninButton.addTarget(self, action: #selector(tapKakuninButton(_:)), for: .touchUpInside)
        view.addSubview(kakuninButton)
        
        kakuninButton.translatesAutoresizingMaskIntoConstraints = false
        kakuninButton.isHidden = true /// ボタン非表示
        NSLayoutConstraint.activate([
            kakuninButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            kakuninButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            kakuninButton.topAnchor.constraint(equalTo: PickerView.bottomAnchor, constant: 20),
            kakuninButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return roomArray.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return roomArray[row].id
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            print(roomArray[row].id)
            goal = roomArray[row].index
        default:
            break
        }
    }

    @objc func tapKakuninButton(_ sender: UIButton) {
        print(PickerView.selectedRow(inComponent: 0))
        
        PickerView.removeFromSuperview()
        kakuninButton.removeFromSuperview()
        
        self.kakuninButton.isHidden = false /// ボタン非表示
        
        let nodes = createNodes()
        if let startNode = nodes[start], let goalNode = nodes[goal] {
            let path = aStar(startNode: startNode, goalNode: goalNode)
            
            for node in path {
                addSpheres(at: position, normal: normal, right: right, node: node)
            }
            
            DispatchQueue.main.async {
                self.showLoadingView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.hideLoadingView()
                }
            }
        }
    }
    
    func createNodes() -> [Character: Node] {
        let map = [
            "#####",
            "#GsH#",
            "##r##",
            "##q##",
            "#FpI#",
            "##o##",
            "##n##",
            "#EmJ#",
            "##l##",
            "##k##",
            "#Dj##",
            "##i##",
            "##h##",
            "#Cg##",
            "##f##",
            "##e##",
            "#BdM#",
            "##c##",
            "##b##",
            "#AaN#",
            "#####"
        ]

        var nodes: [Character: Node] = [:]
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        for (i, row) in map.enumerated() {
            for (j, char) in row.enumerated() {
                if char != "#" {
                    nodes[char] = Node(id: char, x: i, y: j)
                }
            }
        }

        for node in nodes.values {
            for direction in directions {
                let nx = node.x + direction.0
                let ny = node.y + direction.1
                if nx >= 0 && ny >= 0 && nx < map.count && ny < map[nx].count {
                    let neighborChar = Array(map[nx])[ny]
                    if neighborChar != "#", let neighbor = nodes[neighborChar] {
                        node.neighbors.append(neighbor)
                    }
                }
            }
        }
        
        return nodes
    }
}

extension ViewController {
    private func setupSceneView() {
        sceneView = ARSCNView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        sceneView.delegate = self
        view.addSubview(sceneView)
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }

    private func setupScene() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        let lightNode = SCNNode()
        let light = SCNLight()
        lightNode.light = light
        scene.rootNode.addChildNode(lightNode)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                locationService.locationManager?.requestWhenInUseAuthorization()
            case .restricted, .denied:
                presentMessage(title: "Error", message: "Location services are not enabled or permission is denied.")
            case .authorizedWhenInUse, .authorizedAlways:
                runSession()
            @unknown default:
                fatalError("Unknown authorization status")
            }
        } else {
            presentMessage(title: "Error", message: "Location services are not enabled.")
        }
    }
}

extension ViewController: MessagePresenting {
    func runSession() {
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = [.horizontal, .vertical]
        
        guard let nameplateImage = UIImage(named: "nameplate"),
              let cgImage = nameplateImage.cgImage else {
            fatalError("Failed to load nameplate image")
        }
        let referenceImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: 0.2) // 実際の表札サイズに合わせて調整してください
        referenceImage.name = "nameplate"
        configuration.detectionImages = [referenceImage]
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func restartSession() {
        // 現在のセッションを停止
        sceneView.session.pause()
        
        // 既存のアンカーを削除
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // 新しいセッションを開始
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        configuration.planeDetection = [.horizontal, .vertical]
        
        if let nameplateImage = UIImage(named: "nameplate"),
           let cgImage = nameplateImage.cgImage {
            let referenceImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: 0.2)
            referenceImage.name = "nameplate"
            configuration.detectionImages = [referenceImage]
        }
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        if let arError = error as? ARError {
            switch arError.errorCode {
            case 102:
                configuration.worldAlignment = .gravity
                restartSessionWithoutDelete()
            default:
                restartSessionWithoutDelete()
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            print("ready")
        case .notAvailable:
            print("wait")
        case .limited(let reason):
            print("limited tracking state: \(reason)")
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        presentMessage(title: "Error", message: "Session Interruption")
    }
    
    func restartSessionWithoutDelete() {
        sceneView.session.pause()
        print("reset")
    }
}

extension ViewController: LocationServiceDelegate {
    func trackingLocation(for currentLocation: CLLocation) {}

    func modifyLocationCoordinates(location: CLLocation, newLatitude: CLLocationDegrees, newLongitude: CLLocationDegrees) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude),
            altitude: location.altitude,
            horizontalAccuracy: location.horizontalAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            course: location.course,
            speed: location.speed,
            timestamp: location.timestamp
        )
    }

    func trackingLocationDidFail(with error: Error) {
        print("error")
    }
}

extension ViewController {
    private func setupLocationService() {
        locationService = LocationService()
        locationService.delegate = self
    }
}

/// Text Detection
extension ViewController {
    private func setupTextDetection() {
        textDetectionRequest = VNRecognizeTextRequest { [weak self] request, error in
            if let observations = request.results as? [VNRecognizedTextObservation] {
                guard self!.isTextRecognitionRunning else {
                    print("Text recognition is already running.")
                    return
                }
                self?.processObservations(observations)
            }
        }
        textDetectionRequest?.recognitionLevel = .accurate
    }
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) {
        guard let _ = sceneView else { return }
        guard isTextRecognitionRunning else {
            print("Text recognition is already running.")
            return
        }
            
        for observation in observations {
            let topCandidates = observation.topCandidates(1)
            if let candidate = topCandidates.first {
                let text = candidate.string
                print(text)
                if roomArray.contains(where: { $0.id == text }) {
                    stopTextRecognition()
                    detectedText = roomArray.first(where: { $0.id == text })!
                    DispatchQueue.main.sync {
                        showAlert(text: detectedText)
                        
                        if let currentFrame = sceneView.session.currentFrame {
                            let transform = currentFrame.camera.transform
                            startLocation = transform
                            print("start location: \(transform)")
                        }
                    }
                }
            }
        }
    }
    
    func stopTextRecognition() {
        guard isTextRecognitionRunning else {
            print("Text recognition is not running.")
            return
        }

        isTextRecognitionRunning = false
        detectedText = (id: "", index: "H")
    }
    
    func restartTextRecognition() {
        isTextRecognitionRunning = true
    }
}

extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(lastProcessingTime) >= processInterval else { return }
        lastProcessingTime = currentTime
        
        guard let frame = sceneView.session.currentFrame else { return }
        let pixelBuffer = frame.capturedImage
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform([self.textDetectionRequest!])
        } catch {
            print("Failed to perform text-detection request: \(error)")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor,
              imageAnchor.name == "nameplate" else { return }
        
        position = SCNVector3(imageAnchor.transform.columns.3.x,
                              imageAnchor.transform.columns.3.y,
                              imageAnchor.transform.columns.3.z)
        
        normal = SCNVector3(imageAnchor.transform.columns.1.x,
                            imageAnchor.transform.columns.1.y,
                            imageAnchor.transform.columns.1.z)
        
        right = SCNVector3(imageAnchor.transform.columns.0.x,
                           imageAnchor.transform.columns.0.y,
                           imageAnchor.transform.columns.0.z)
        
        restartTextRecognition()
    }
}

/// Confirm Alert
extension ViewController {
    func showAlert(text: (id: String, index: Character)){
        let actionAlert = UIAlertController(title: text.id, message: "Is this the starting point?", preferredStyle: .alert)
        let comfirmAction = UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.start = text.index
            print("Start: \(self?.start ?? "H")")
            
            if self?.isInitialDisplay == true {
                self?.kakuninButton.isHidden = false
                self?.isInitialDisplay = false
                self?.startOrientationRecording()
            } else {
                self?.showLoadingView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    guard let strongSelf = self else { return }
                    let nodes = strongSelf.createNodes()
                    if let startNode = nodes[strongSelf.start], let goalNode = nodes[strongSelf.goal] {
                        let path = aStar(startNode: startNode, goalNode: goalNode)
                        for node in path {
                            strongSelf.addSpheres(at: strongSelf.position, normal: strongSelf.normal, right: strongSelf.right, node: node)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                            strongSelf.hideLoadingView()
                        }
                    }
                }
            }
            print("Okのシートが選択されました。")
        })
        actionAlert.addAction(comfirmAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            self?.restartTextRecognition()
            print("キャンセルのシートが押されました。")
        })
        actionAlert.addAction(cancelAction)
        
        present(actionAlert, animated: true, completion: nil)
    }
}

/// AR
extension ViewController {
    func addSpheres(at position: SCNVector3, normal: SCNVector3, right: SCNVector3, node: Node) {
        var arrowNode = SCNNode()
        
        if arrowNodes.isEmpty {
            arrowNode = createCone(color: .green.withAlphaComponent(0.9), radius: 0.3)
            let arrowPosition = SCNVector3(
                position.x + normal.x * 0.0,
                position.y + normal.y * 0.0,
                position.z + normal.z * 0.0
            )
            arrowNode.position = arrowPosition
            lastSpherePosition = arrowPosition
            
            if !arrowNodes.isEmpty {
                rotateNode(arrowNodes.last!, to: arrowNode.position)
            }
            
            let cubeNode = createCube(color: .red.withAlphaComponent(0.9), size: 0.2)
            arrowNode.addChildNode(cubeNode)
            cubeNode.position = SCNVector3(0, -0.3, 0)
        } else {
            arrowNode = createCone(color: .blue.withAlphaComponent(0.9), radius: 0.3)
            let distance: Float
            var spherePosition: SCNVector3
            
            switch node.pointType {
            case 1:
                distance = 2.2
                spherePosition = SCNVector3(
                    position.x + normal.x * distance,
                    position.y + normal.y * distance,
                    position.z + normal.z * distance
                )
            case 2:
                distance = 9.1 / 3
                spherePosition = SCNVector3(
                    lastSpherePosition.x + right.x * distance,
                    lastSpherePosition.y + right.y * distance,
                    lastSpherePosition.z + right.z * distance
                )
            case 3:
                distance = -9.1 / 3
                spherePosition = SCNVector3(
                    lastSpherePosition.x + right.x * distance,
                    lastSpherePosition.y + right.y * distance,
                    lastSpherePosition.z + right.z * distance
                )
            case 4:
                distance = 2.2
                spherePosition = SCNVector3(
                    lastSpherePosition.x + normal.x * distance,
                    lastSpherePosition.y + normal.y * distance,
                    lastSpherePosition.z + normal.z * distance
                )
            case 5:
                distance = -2.2
                spherePosition = SCNVector3(
                    lastSpherePosition.x + normal.x * distance,
                    lastSpherePosition.y + normal.y * distance,
                    lastSpherePosition.z + normal.z * distance
                )
            default:
                return
            }
            
            arrowNode.position = spherePosition
            lastSpherePosition = spherePosition
            
            if !arrowNodes.isEmpty {
                rotateNode(arrowNodes.last!, to: arrowNode.position)
            }
            
            let cubeNode = createCube(color: .red.withAlphaComponent(0.9), size: 0.2)
            arrowNode.addChildNode(cubeNode)
            cubeNode.position = SCNVector3(0, -0.3, 0)
        }
        
        sceneView.scene.rootNode.addChildNode(arrowNode)
        arrowNodes.append(arrowNode)
    }

    func createCone(color: UIColor, radius: CGFloat) -> SCNNode {
        let cone = SCNCone(topRadius: 0, bottomRadius: radius, height: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = color
        cone.materials = [material]
        return SCNNode(geometry: cone)
    }

    func createCube(color: UIColor, size: CGFloat) -> SCNNode {
        let cube = SCNBox(width: size, height: size, length: size, chamferRadius: 0.003)
        let material = SCNMaterial()
        material.diffuse.contents = color
        cube.materials = [material]
        return SCNNode(geometry: cube)
    }

    func rotateNode(_ node: SCNNode, to direction: SCNVector3) {
        let directionVector = SCNVector3ToGLKVector3(direction)
        let nodeDirection = SCNVector3(0, 1, 0) // ノードの初期方向
        let nodeDirectionGLK = SCNVector3ToGLKVector3(nodeDirection)
        
        let crossProduct = GLKVector3CrossProduct(nodeDirectionGLK, directionVector)
        let dotProduct = GLKVector3DotProduct(GLKVector3Normalize(nodeDirectionGLK), GLKVector3Normalize(directionVector))
        let angle = acos(dotProduct)
        
        print("-------------")
        print(crossProduct.x)
        print(crossProduct.y)
        print(crossProduct.z)
        
        node.rotation = SCNVector4(crossProduct.x, crossProduct.y, crossProduct.z, angle)
    }

    func SCNVector3ToGLKVector3(_ vector: SCNVector3) -> GLKVector3 {
        return GLKVector3Make(vector.x, vector.y, vector.z)
    }
    
    // Function to calculate distance between two SCNVector3 points
    func distanceBetweenPoints(_ pointA: SCNVector3, _ pointB: SCNVector3) -> Float {
        let dx = pointB.x - pointA.x
        let dy = pointB.y - pointA.y
        let dz = pointB.z - pointA.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    // Function to get distances from the camera to all sphere nodes
    func getDistancesToSpheres() {
        guard let cameraNode = sceneView.pointOfView else { return }
        let cameraPosition = cameraNode.position
        
        guard !arrowNodes.isEmpty else {
            print("0 node")
            return
        }
        let spherePosition = arrowNodes.first!.position
        let distance = distanceBetweenPoints(cameraPosition, spherePosition)
        if distance <= 1 {
            removeSphere()
        }
        print("--------------------------------------------")
        print("Distance to sphere at \(spherePosition): \(distance) meters")
    }
    
    func removeSphere() {
        let sphereNode = arrowNodes.first!
        sphereNode.removeFromParentNode()
        arrowNodes.removeFirst()
    }
}

extension ViewController {
    func showLoadingView() {
        let loadingView = UIView(frame: sceneView.bounds)
        loadingView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        loadingView.tag = 1001  // Tag to identify the loading view

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = loadingView.center
        activityIndicator.startAnimating()

        let label = UILabel()
        label.text = "Do not move your device"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(label)
        sceneView.addSubview(loadingView)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
        ])
    }

    func hideLoadingView() {
        if let loadingView = sceneView.viewWithTag(1001) {
            loadingView.removeFromSuperview()
        }
    }
}

extension SCNQuaternion {
    init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.init()
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}

/// Get and Record Orientation
extension ViewController {
    func createFile() {
        let fileManager = FileManager.default
        do {
            let currentTime = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let currentTimeString = dateFormatter.string(from: currentTime)
            
            let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentsURL.appendingPathComponent("AR_orientationRecords_\(currentTimeString).csv")
                    
            // CSVファイルのヘッダー
            var csvText = "timestamp,orientation\n"
                    
            // orientationRecords配列をCSV形式に変換
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            for record in orientationRecords {
                let dateString = dateFormatter.string(from: record.timestamp)
                csvText += "\(dateString),\(record.orientation)\n"
            }
                    
            // データをファイルに書き込み
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
                print("CSV file created successfully at \(fileURL.path)")
            } catch {
                print("Error creating CSV file: \(error.localizedDescription)")
            }
    }
    
    @objc func checkOrientation() {
        let orientation = UIDevice.current.orientation
        let orientationValue = getOrientationValue(orientation)
        let currentTime = Date()
        let record = OrientationRecord(timestamp: currentTime, orientation: orientationValue)
        orientationRecords.append(record)
        print("Recorded Orientation at \(currentTime): \(orientationValue)")
    }
    
    func getOrientationValue(_ orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .unknown:
            return 0
        case .portrait:
            return 1
        case .portraitUpsideDown:
            return 2
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 4
        case .faceUp:
            return 5
        case .faceDown:
            return 6
        @unknown default:
            return -1
        }
    }
    
    func startOrientationRecording() {
        // 既にタイマーが動作している場合は無視する
        guard orientationTimer == nil else { return }
        
        orientationTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(checkOrientation), userInfo: nil, repeats: true)
        print("Orientation recording started.")
    }
    
    func stopOrientationRecording() {
        orientationTimer?.invalidate()
        orientationTimer = nil
        print("Orientation recording stopped.")
    }
}
