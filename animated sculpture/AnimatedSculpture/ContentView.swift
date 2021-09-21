//
//  ContentView.swift
//  AnimatedSculpture
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
    
    @Published var positionLocked = false
    @Published var sliderValue: Double = 0.002
    
    enum UISignal {
        case lockPosition
    }
}


// MARK: - UI Layer.
struct ContentView : View {
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
            
            HStack {
                Button {
                    viewModel.uiSignal.send(.lockPosition)
                } label: {
                    Label("Lock Position", systemImage: "target")
                        .font(.system(.title))
                        .foregroundColor(.white)
                        .labelStyle(IconOnlyLabelStyle())
                        .frame(width: 44, height: 44)
                        .opacity(viewModel.positionLocked ? 0.25 : 1.0)
                }
                
                Slider(value: $viewModel.sliderValue, in: 0.002...0.01)
                    .accentColor(.white)
                
                Button {
                    viewModel.uiSignal.send(.lockPosition)
                } label: {
                    Label("Boom", systemImage: "target")
                        .font(.system(.title))
                        .foregroundColor(.white)
                        .labelStyle(IconOnlyLabelStyle())
                        .frame(width: 44, height: 44)
                        .opacity(viewModel.positionLocked ? 0.25 : 1.0)
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 10)
            .padding(.bottom, 30)
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
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


    // TODO: Add any local variables here. //////////////////////////////////////
    
    var boxEntity: Entity!
    var sphereEntity: Entity!
    
    var piggyBank: Entity!
//    var piggyBankStartScale:
    
    
    var coin: Entity!
    let coinTopY: Float = 0.60
    var coins: Float = 0
    var moveCoin = true
    

    var upDnToggle = false

    
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
            // Update cursor position when position is not locked.
            if !self.viewModel.positionLocked {
                self.updateCursor()
            }
            
            // Call renderLoop method on every frame.
            self.renderLoop()
        }.store(in: &subscriptions)
        
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }.store(in: &subscriptions)
    }
    
    // Process UI signals.
    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .lockPosition:
            viewModel.positionLocked.toggle()
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
    
    // TODO: Setup entities. //////////////////////////////////////
    func setupEntities() {
        // Create an anchor at scene origin.
        originAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(originAnchor)

        // Create and add empty cursor entity to origin anchor.
        cursor = Entity()
        originAnchor.addChild(cursor)
        
        piggyBank = try? Entity.load(named: "piggy-bank.usdz")
        piggyBank.position.y = -0.4;
        print(piggyBank.scale);
        cursor.addChild(piggyBank)
        
        coin = try? Entity.load(named: "coin.usdz")
        coin.position.y = coinTopY;
        cursor.addChild(coin)
    }


    // TODO: Animate entities. //////////////////////////////////////
    func renderLoop() {
        // Slider value from UI.
        let sliderValue = Float(viewModel.sliderValue)
        
        if(piggyBank.position.y + 0.203 > coin.position.y + 0.066){
            coin.position.y = coinTopY
            coins += 1.0
            piggyBank.scale = [1 + 0.35 * coins, 1 + 0.35 * coins, 1 + 0.35 * coins]
            print(piggyBank.scale.x)
            if(piggyBank.scale.x > 3.5 ){
                moveCoin = false
                coin.position.y = coinTopY
            }
        }
        
        if(moveCoin){
            coin.transform.rotation *= simd_quatf(angle: .pi/16, axis: SIMD3<Float>(0,1,0))
            coin.position.y -= sliderValue;
        }
        
    }
}
