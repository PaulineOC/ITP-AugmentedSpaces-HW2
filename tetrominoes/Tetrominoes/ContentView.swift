//
//  ContentView.swift
//  Tetrominoes
//
//  Created by Nien Lam on 9/15/21.
//  Copyright © 2021 Line Break, LLC. All rights reserved.
//

import SwiftUI
import ARKit
import RealityKit
import Combine


// MARK: - View model for handling communication between the UI and ARView.
class ViewModel: ObservableObject {
    let uiSignal = PassthroughSubject<UISignal, Never>()
    
    enum UISignal {
        case straightSelected
        case squareSelected
        case tSelected
        case lSelected
        case skewSelected
    }
}


// MARK: - UI Layer.
struct ContentView : View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        ZStack {
            // AR View.
            ARViewContainer(viewModel: viewModel)
            
            // Bottom buttons.
            HStack {
                Button {
                    viewModel.uiSignal.send(.straightSelected)
                } label: {
                    tetrominoIcon("straight", color: Color(red: 0, green: 1, blue: 1))
                }
                
                Button {
                    viewModel.uiSignal.send(.squareSelected)
                } label: {
                    tetrominoIcon("square", color: .yellow)
                }
                
                Button {
                    viewModel.uiSignal.send(.tSelected)
                } label: {
                    tetrominoIcon("t", color: .purple)
                }
                
                Button {
                    viewModel.uiSignal.send(.lSelected)
                } label: {
                    tetrominoIcon("l", color: .orange)
                }
                
                Button {
                    viewModel.uiSignal.send(.skewSelected)
                } label: {
                    tetrominoIcon("skew", color: .green)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 30)
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
    
    // Helper method for rendering icon.
    func tetrominoIcon(_ image: String, color: Color) -> some View {
        Image(image)
            .resizable()
            .padding(3)
            .frame(width: 44, height: 44)
            .background(color)
            .cornerRadius(5)
    }
}


// MARK: - AR View.
struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    
    func makeUIView(context: Context) -> ARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

class SimpleARView: ARView {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var originAnchor: AnchorEntity!
    var subscriptions = Set<AnyCancellable>()
    
    // Empty entity for cursor.
    var cursor: Entity!
    
    // Root entities for pieces.
    var straightEntity: Entity!
    var squareEntity: Entity!
    var tEntity: Entity!
    var lEntity: Entity!
    var skewEntity: Entity!
    
    init(frame: CGRect, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupScene()
        
        setupEntities()

        // Enable straight piece on startup.
        straightEntity.isEnabled  = true
        squareEntity.isEnabled    = false
        tEntity.isEnabled         = false
        lEntity.isEnabled         = false
        skewEntity.isEnabled      = false
    }
    
    func setupScene() {
        // Setup world tracking and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]
        arView.session.run(configuration)
        
        // Called every frame.
        scene.subscribe(to: SceneEvents.Update.self) { event in
            self.updateCursor()
        }.store(in: &subscriptions)
        
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }.store(in: &subscriptions)
    }
    
    // Hide/Show active tetromino.
    func processUISignal(_ signal: ViewModel.UISignal) {
        straightEntity.isEnabled  = false
        squareEntity.isEnabled    = false
        tEntity.isEnabled         = false
        lEntity.isEnabled         = false
        skewEntity.isEnabled      = false
        
        switch signal {
        case .straightSelected:
            straightEntity.isEnabled = true
        case .squareSelected:
            squareEntity.isEnabled = true
        case .tSelected:
            tEntity.isEnabled = true
        case .lSelected:
            lEntity.isEnabled = true
        case .skewSelected:
            skewEntity.isEnabled = true
        }
    }
    
    // Move cursor to plane detected.
    func updateCursor() {
        // Raycast to get cursor position.
        let results = raycast(from: center,
                              allowing: .existingPlaneGeometry,
                              alignment: .any)
        
        // Move cursor to position if hitting plane.
        if let result = results.first {
            cursor.isEnabled = true
            cursor.move(to: result.worldTransform, relativeTo: originAnchor)
        } else {
            cursor.isEnabled = false
        }
    }
    
    func setupEntities() {
        // Create an anchor at scene origin.
        originAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(originAnchor)
        
        // Create and add empty cursor entity to origin anchor.
        cursor = Entity()
        originAnchor.addChild(cursor)
        
        // Create root tetrominoes. ////
        
        // Box mesh.
        let boxSize: Float      = 0.05
        let cornerRadius: Float = 0.002
        let boxMesh = MeshResource.generateBox(size: boxSize, cornerRadius: cornerRadius)
        
        // Colored materials.
        let cyanMaterial    = SimpleMaterial(color: .cyan, isMetallic: false)
        let yellowMaterial  = SimpleMaterial(color: .yellow, isMetallic: false)
        let purpleMaterial  = SimpleMaterial(color: .purple, isMetallic: false)
        let orangeMaterial  = SimpleMaterial(color: .orange, isMetallic: false)
        let greenMaterial   = SimpleMaterial(color: .green, isMetallic: false)
        
        // Create an relative origin entity for centering the root box of each tetromino.
        let relativeOrigin = Entity()
        relativeOrigin.position.y = boxSize / 2
        cursor.addChild(relativeOrigin)
        
        // Straight piece.
        straightEntity = ModelEntity(mesh: boxMesh, materials: [cyanMaterial])
        relativeOrigin.addChild(straightEntity)
        
        // Square piece.
        squareEntity = ModelEntity(mesh: boxMesh, materials: [yellowMaterial])
        relativeOrigin.addChild(squareEntity)
        
        // T piece.
        tEntity = ModelEntity(mesh: boxMesh, materials: [purpleMaterial])
        relativeOrigin.addChild(tEntity)
        
        // L piece.
        lEntity = ModelEntity(mesh: boxMesh, materials: [orangeMaterial])
        relativeOrigin.addChild(lEntity)
        
        // Skew piece.
        skewEntity = ModelEntity(mesh: boxMesh, materials: [greenMaterial])
        relativeOrigin.addChild(skewEntity)
        
        
        // TODO: Create tetrominoes //////////////////////////////////////
        
        // ... create straight piece.
        
        // 1. Clone new cube.
        let secondCubeStraight = straightEntity.clone(recursive: false)
        let thirdCubeStraight = straightEntity.clone(recursive: false)
        let fourthStraightCube = straightEntity.clone(recursive: false)
        
        // 2. Set position based on root tetromino entity.
        secondCubeStraight.position.y = boxSize
        thirdCubeStraight.position.y = boxSize * 2
        fourthStraightCube.position.y = boxSize * 3
                
        // 3. Add child to root tetromino entity.
        straightEntity.addChild(secondCubeStraight)
        straightEntity.addChild(thirdCubeStraight)
        straightEntity.addChild(fourthStraightCube)

        // ... create square piece.
        
        let topLeftSquare = squareEntity.clone(recursive: false)
        topLeftSquare.position.y = boxSize
        
        let bottomRightSquare = squareEntity.clone(recursive: false)
        bottomRightSquare.position.x = boxSize
    
        let topRightSquare = squareEntity.clone(recursive: false)
        topRightSquare.position.y = boxSize
        topRightSquare.position.x = boxSize
        
        squareEntity.addChild(topLeftSquare)
        squareEntity.addChild(bottomRightSquare)
        squareEntity.addChild(topRightSquare)
        

        // ... create t piece.
        
        let secondCubeT = tEntity.clone(recursive: false)
        secondCubeT.position.x = boxSize
        tEntity.addChild(secondCubeT)
        
        let topCubeT = secondCubeT.clone(recursive: false)
        topCubeT.position.y += boxSize
        tEntity.addChild(topCubeT)

        let thirdCubeT = secondCubeT.clone(recursive: false)
        thirdCubeT.position.x += boxSize
        tEntity.addChild(thirdCubeT);
        
        // ... create l piece.
        let secondCubeL = lEntity.clone(recursive: false)
        secondCubeL.position.y += boxSize
        lEntity.addChild(secondCubeL)
        
        let thirdCubeL = secondCubeL.clone(recursive: false)
        thirdCubeL.position.y += boxSize
        lEntity.addChild(thirdCubeL)
        
        let rightCubeL = lEntity.clone(recursive: false)
        rightCubeL.position.x += boxSize
        lEntity.addChild(rightCubeL)
        
        // ... create skew piece.
        let bottomSecond = skewEntity.clone(recursive: false)
        bottomSecond.position.x = boxSize
        skewEntity.addChild(bottomSecond)
        
        let topFirst = bottomSecond.clone(recursive: false)
        topFirst.position.y += boxSize
        skewEntity.addChild(topFirst)
        
        let topSecond = topFirst.clone(recursive: false)
        topSecond.position.x += boxSize
        skewEntity.addChild(topSecond)

        
        /////////////////////////////////////////////////////////////////////////
    }
}
