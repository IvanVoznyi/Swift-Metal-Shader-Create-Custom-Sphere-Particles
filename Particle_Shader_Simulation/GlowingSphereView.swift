//
//  GlowingSphereView.swift
//  Particle_Sphere_Simulation
//
//  Created by Ivan Voznyi on 12/29/25.
//

import SwiftUI


struct GlowingSphereView: View {
    @State var rotationSpeed: Float = 0.1
    @State var density: Double = 40

    let startDate = Date()
    let radius = 0.65

        var body: some View {
            ZStack{
                Slider(value: $density, in: 10...250, step: 10.0, label: {} )
                    .offset(x: 0, y: -350)
                    .zIndex(1)
                    .opacity(0.1)
                TimelineView(.animation) { context in
                    GeometryReader { proxy in
                        let size = proxy.size
                        Rectangle()
                            .frame(width: size.width, height: size.height)
                            .colorEffect(
                                ShaderLibrary.particleSphere(
                                    .float2(size.width, size.height),
                                    .float(startDate.timeIntervalSinceNow),
                                    .float(radius),
                                    .float(density),
                                    .float(rotationSpeed)
                                    )
                            )
                    }
                }
            }.ignoresSafeArea()
        }
}

#Preview {
    GlowingSphereView()
}
